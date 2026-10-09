using System.Collections.Generic;
using UnityEngine;

namespace Gameplay.Pathfinding
{
    public class PathfindingManager : MonoBehaviour
    {
        public static PathfindingManager Instance { get; private set; }

        [Header("Grid Configuration")]
        [SerializeField] private PathfindingGridData gridData;

        private PathfindingGrid pathfindingGrid;

        public PathfindingGrid Grid => pathfindingGrid;
        public PathfindingGridData GridData => gridData;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            LoadGridFromConfig();
        }

        public void LoadGridFromConfig()
        {
            if (gridData != null)
            {
                pathfindingGrid = PathfindingGrid.CreateFromData(gridData);
            }
            else
            {
                Debug.LogWarning("[PathfindingManager] No PathfindingGridData assigned! Please assign a Grid Data asset in the Inspector.");
            }
        }

        public void InitializeGrid(PathfindingGridData data)
        {
            gridData = data;
            LoadGridFromConfig();
        }

        public List<Vector2> FindPath(Vector2 start, Vector2 goal)
        {
            if (pathfindingGrid == null)
            {
                Debug.LogWarning("[PathfindingManager] PathfindingGrid is not initialized!");
                return null;
            }

            Vector2Int startCell, goalCell;

            if (pathfindingGrid.WorldToGrid(start, out startCell) && pathfindingGrid.WorldToGrid(goal, out goalCell))
            {
                List<Vector2Int> pathRaw = AStarPathfinder.FindPath(pathfindingGrid.Cells, startCell, goalCell);
                List<Vector2> pathWorld = new();

                if (pathRaw != null)
                {
                    foreach (Vector2Int cell in pathRaw)
                    {
                        Vector2 worldPos = pathfindingGrid.GridToWorld(cell.x, cell.y, true);
                        pathWorld.Add(worldPos);
                    }

                    return pathWorld;
                }
            }

            return null;
        }
    }
}