using System;
using System.Collections.Generic;
using UnityEngine;

namespace Gameplay.Pathfinding
{
    [ExecuteAlways]
    [SelectionBase]
    public class PathfindingGridDebugger : MonoBehaviour
    {
        [Header("Grid Dimensions")]
        [Min(1)]
        [SerializeField] private int width = 16;
        [Min(1)]
        [SerializeField] private int height = 12;
        [Min(0.1f)]
        [SerializeField] private float cellSize = 1.0f;
        [SerializeField] private Vector2 originOffset = Vector2.zero;

        [Header("Physics Scan")]
        [SerializeField] private LayerMask obstacleLayer;
        [Range(0.1f, 1f)]
        [SerializeField] private float obstacleCheckScale = 0.85f;

        [Header("Pathfinding Points")]
        [SerializeField] private Vector2Int startPoint = new Vector2Int(1, 1);
        [SerializeField] private Vector2Int endPoint = new Vector2Int(10, 10);

        [Header("Visualization Settings")]
        [SerializeField] private bool showGrid = true;
        [SerializeField] private bool showWalkableWireframes = true;
        [SerializeField] private bool showObstacles = true;
        [SerializeField] private bool showPath = true;
        [SerializeField] private bool autoUpdatePath = true;

        [Header("Data Asset")]
        [SerializeField] private PathfindingGridData gridDataAsset;

        [Header("Saved Obstacles")]
        [SerializeField] private List<Vector2Int> manualObstacles = new List<Vector2Int>();

        // Runtime/Cached objects
        private PathfindingGrid grid;
        private HashSet<Vector2Int> obstacleSet = new HashSet<Vector2Int>();
        private List<Vector2Int> currentPath;
        private bool lastPathSearchSucceeded = false;
        private string lastSearchMessage = "No search performed yet";

        // Properties for Editor access
        public PathfindingGridData GridDataAsset
        {
            get => gridDataAsset;
            set => gridDataAsset = value;
        }
        public PathfindingGrid Grid => grid;
        public int Width => width;
        public int Height => height;
        public float CellSize => cellSize;
        public Vector2 OriginOffset => originOffset;
        public Vector2 WorldOrigin => (Vector2)transform.position + originOffset;
        public Vector2Int StartPoint => startPoint;
        public Vector2Int EndPoint => endPoint;
        public LayerMask ObstacleLayer => obstacleLayer;
        public bool AutoUpdatePath => autoUpdatePath;
        public List<Vector2Int> CurrentPath => currentPath;
        public bool LastPathSearchSucceeded => lastPathSearchSucceeded;
        public string LastSearchMessage => lastSearchMessage;
        public int ObstacleCount => obstacleSet.Count;
        public IReadOnlyList<Vector2Int> ManualObstacles => manualObstacles;

        private void OnEnable()
        {
            RebuildGrid();
        }

        private void OnValidate()
        {
            RebuildGrid();
        }

        public void RebuildGrid()
        {
            grid = new PathfindingGrid(width, height, cellSize, WorldOrigin);
            obstacleSet = new HashSet<Vector2Int>(manualObstacles);

            // Apply manual obstacles to the grid
            foreach (var obs in obstacleSet)
            {
                if (grid.InBounds(obs))
                {
                    grid.SetWalkable(obs, false);
                }
            }

            // Clamp start and end points within bounds
            startPoint = new Vector2Int(
                Mathf.Clamp(startPoint.x, 0, width - 1),
                Mathf.Clamp(startPoint.y, 0, height - 1)
            );
            endPoint = new Vector2Int(
                Mathf.Clamp(endPoint.x, 0, width - 1),
                Mathf.Clamp(endPoint.y, 0, height - 1)
            );

            if (autoUpdatePath)
            {
                FindPath();
            }
        }

        public void ScanPhysicsColliders()
        {
            if (grid == null) RebuildGrid();

            grid.ScanColliders(obstacleLayer, obstacleCheckScale);
            manualObstacles.Clear();
            obstacleSet.Clear();

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    if (!grid.IsWalkable(x, y))
                    {
                        var pos = new Vector2Int(x, y);
                        manualObstacles.Add(pos);
                        obstacleSet.Add(pos);
                    }
                }
            }

            if (autoUpdatePath)
            {
                FindPath();
            }
        }

        public void SetStartPoint(Vector2Int pos)
        {
            if (!grid.InBounds(pos)) return;
            startPoint = pos;
            if (autoUpdatePath) FindPath();
        }

        public void SetEndPoint(Vector2Int pos)
        {
            if (!grid.InBounds(pos)) return;
            endPoint = pos;
            if (autoUpdatePath) FindPath();
        }

        public void AddObstacle(Vector2Int pos)
        {
            if (grid == null || !grid.InBounds(pos)) return;
            if (obstacleSet.Add(pos))
            {
                manualObstacles.Add(pos);
                grid.SetWalkable(pos, false);
                if (autoUpdatePath) FindPath();
            }
        }

        public void AddObstaclesBox(Vector2Int min, Vector2Int max)
        {
            if (grid == null) RebuildGrid();

            int minX = Mathf.Clamp(Mathf.Min(min.x, max.x), 0, width - 1);
            int maxX = Mathf.Clamp(Mathf.Max(min.x, max.x), 0, width - 1);
            int minY = Mathf.Clamp(Mathf.Min(min.y, max.y), 0, height - 1);
            int maxY = Mathf.Clamp(Mathf.Max(min.y, max.y), 0, height - 1);

            bool changed = false;
            for (int x = minX; x <= maxX; x++)
            {
                for (int y = minY; y <= maxY; y++)
                {
                    var pos = new Vector2Int(x, y);
                    if (obstacleSet.Add(pos))
                    {
                        manualObstacles.Add(pos);
                        grid.SetWalkable(pos, false);
                        changed = true;
                    }
                }
            }

            if (changed && autoUpdatePath)
            {
                FindPath();
            }
        }

        public void RemoveObstacle(Vector2Int pos)
        {
            if (grid == null || !grid.InBounds(pos)) return;
            if (obstacleSet.Remove(pos))
            {
                manualObstacles.Remove(pos);
                grid.SetWalkable(pos, true);
                if (autoUpdatePath) FindPath();
            }
        }

        public void RemoveObstaclesBox(Vector2Int min, Vector2Int max)
        {
            if (grid == null) RebuildGrid();

            int minX = Mathf.Clamp(Mathf.Min(min.x, max.x), 0, width - 1);
            int maxX = Mathf.Clamp(Mathf.Max(min.x, max.x), 0, width - 1);
            int minY = Mathf.Clamp(Mathf.Min(min.y, max.y), 0, height - 1);
            int maxY = Mathf.Clamp(Mathf.Max(min.y, max.y), 0, height - 1);

            bool changed = false;
            for (int x = minX; x <= maxX; x++)
            {
                for (int y = minY; y <= maxY; y++)
                {
                    var pos = new Vector2Int(x, y);
                    if (obstacleSet.Remove(pos))
                    {
                        manualObstacles.Remove(pos);
                        grid.SetWalkable(pos, true);
                        changed = true;
                    }
                }
            }

            if (changed && autoUpdatePath)
            {
                FindPath();
            }
        }

        public void ToggleObstacle(Vector2Int pos)
        {
            if (obstacleSet.Contains(pos))
            {
                RemoveObstacle(pos);
            }
            else
            {
                AddObstacle(pos);
            }
        }

        public void ClearObstacles()
        {
            manualObstacles.Clear();
            obstacleSet.Clear();
            RebuildGrid();
        }

        public void ClearPath()
        {
            currentPath = null;
            lastPathSearchSucceeded = false;
            lastSearchMessage = "Path cleared";
        }

        public void SaveToDataAsset(PathfindingGridData targetAsset = null)
        {
            var asset = targetAsset != null ? targetAsset : gridDataAsset;
            if (asset == null)
            {
                Debug.LogWarning("[PathfindingGridDebugger] No PathfindingGridData asset assigned to save to!");
                return;
            }

            asset.SetData(width, height, cellSize, WorldOrigin, manualObstacles);
#if UNITY_EDITOR
            UnityEditor.EditorUtility.SetDirty(asset);
            UnityEditor.AssetDatabase.SaveAssets();
#endif
            Debug.Log($"[PathfindingGridDebugger] Successfully saved grid data ({width}x{height}, {manualObstacles.Count} obstacles) to {asset.name}!");
        }

        public void LoadFromDataAsset(PathfindingGridData targetAsset = null)
        {
            var asset = targetAsset != null ? targetAsset : gridDataAsset;
            if (asset == null)
            {
                Debug.LogWarning("[PathfindingGridDebugger] No PathfindingGridData asset assigned to load from!");
                return;
            }

            width = asset.Width;
            height = asset.Height;
            cellSize = asset.CellSize;
            originOffset = asset.OriginPosition - (Vector2)transform.position;

            manualObstacles.Clear();
            if (asset.BlockedCells != null)
            {
                manualObstacles.AddRange(asset.BlockedCells);
            }

            RebuildGrid();
            Debug.Log($"[PathfindingGridDebugger] Successfully loaded grid data from {asset.name} ({width}x{height}, {manualObstacles.Count} obstacles)!");
        }

        public void FindPath()
        {
            if (grid == null) RebuildGrid();

            if (!grid.InBounds(startPoint) || !grid.InBounds(endPoint))
            {
                currentPath = null;
                lastPathSearchSucceeded = false;
                lastSearchMessage = "Start or Goal point is outside grid bounds.";
                return;
            }

            if (!grid.IsWalkable(startPoint))
            {
                currentPath = null;
                lastPathSearchSucceeded = false;
                lastSearchMessage = $"Start point {startPoint} is blocked (Obstacle)!";
                return;
            }

            if (!grid.IsWalkable(endPoint))
            {
                currentPath = null;
                lastPathSearchSucceeded = false;
                lastSearchMessage = $"Goal point {endPoint} is blocked (Obstacle)!";
                return;
            }

            var timer = System.Diagnostics.Stopwatch.StartNew();
            currentPath = AStarPathfinder.FindPath(grid.Cells, startPoint, endPoint);
            timer.Stop();

            if (currentPath != null && currentPath.Count > 0)
            {
                lastPathSearchSucceeded = true;
                lastSearchMessage = $"Path found! Length: {currentPath.Count} steps ({timer.Elapsed.TotalMilliseconds:F3} ms)";
            }
            else
            {
                lastPathSearchSucceeded = false;
                lastSearchMessage = $"No valid path found from {startPoint} to {endPoint}!";
            }
        }

        private void OnDrawGizmos()
        {
            if (!showGrid || grid == null) return;

            Vector2 origin = WorldOrigin;
            float totalWidth = width * cellSize;
            float totalHeight = height * cellSize;

            // Draw outer grid boundary
            Gizmos.color = new Color(0.2f, 0.8f, 1f, 0.9f);
            Gizmos.DrawWireCube(
                origin + new Vector2(totalWidth * 0.5f, totalHeight * 0.5f),
                new Vector3(totalWidth, totalHeight, 0.05f)
            );

            // Draw individual cells
            Vector3 cellBoxSize = new Vector3(cellSize * 0.9f, cellSize * 0.9f, 0.05f);

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    Vector2 cellPos = grid.GridToWorld(x, y, true);
                    bool isObs = obstacleSet.Contains(new Vector2Int(x, y));

                    if (isObs && showObstacles)
                    {
                        // Red filled cube for obstacles
                        Gizmos.color = new Color(0.9f, 0.15f, 0.15f, 0.65f);
                        Gizmos.DrawCube(cellPos, cellBoxSize);
                        Gizmos.color = new Color(1f, 0.2f, 0.2f, 0.9f);
                        Gizmos.DrawWireCube(cellPos, cellBoxSize);
                    }
                    else if (showWalkableWireframes)
                    {
                        // Subtle wireframe for walkable cells
                        Gizmos.color = new Color(1f, 1f, 1f, 0.12f);
                        Gizmos.DrawWireCube(cellPos, cellBoxSize);
                    }
                }
            }

            // Draw Start Point
            if (grid.InBounds(startPoint))
            {
                Vector2 startWorld = grid.GridToWorld(startPoint, true);
                Gizmos.color = new Color(0.1f, 0.95f, 0.2f, 0.85f);
                Gizmos.DrawCube(startWorld, cellBoxSize);
                Gizmos.color = Color.white;
                Gizmos.DrawWireCube(startWorld, cellBoxSize * 1.05f);
            }

            // Draw Goal / End Point
            if (grid.InBounds(endPoint))
            {
                Vector2 endWorld = grid.GridToWorld(endPoint, true);
                Gizmos.color = new Color(0.1f, 0.6f, 1f, 0.85f);
                Gizmos.DrawCube(endWorld, cellBoxSize);
                Gizmos.color = Color.white;
                Gizmos.DrawWireCube(endWorld, cellBoxSize * 1.05f);
            }

            // Draw Path
            if (showPath && currentPath != null && currentPath.Count > 0)
            {
                Vector3 pathNodeSize = new Vector3(cellSize * 0.35f, cellSize * 0.35f, 0.05f);

                for (int i = 0; i < currentPath.Count; i++)
                {
                    Vector2 nodeWorld = grid.GridToWorld(currentPath[i], true);

                    // Small yellow square at each node center
                    Gizmos.color = new Color(1f, 0.92f, 0.016f, 0.9f);
                    Gizmos.DrawCube(nodeWorld, pathNodeSize);

                    // Connect path segments
                    if (i < currentPath.Count - 1)
                    {
                        Vector2 nextWorld = grid.GridToWorld(currentPath[i + 1], true);
                        Gizmos.color = new Color(1f, 0.85f, 0f, 1f);
                        Gizmos.DrawLine(nodeWorld, nextWorld);
                    }
                }
            }
        }
    }
}
