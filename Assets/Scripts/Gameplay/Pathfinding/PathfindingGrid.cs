using System.Collections.Generic;
using UnityEngine;

namespace Gameplay.Pathfinding
{
    public class PathfindingGrid
    {
        public int Width { get; private set; }
        public int Height { get; private set; }
        public float CellSize { get; private set; }
        public Vector2 OriginPosition { get; private set; }
        public GridCell[,] Cells { get; private set; }

        public PathfindingGrid(int width, int height, float cellSize, Vector2 originPosition)
        {
            Width = Mathf.Max(1, width);
            Height = Mathf.Max(1, height);
            CellSize = Mathf.Max(0.01f, cellSize);
            OriginPosition = originPosition;

            InitializeCells();
        }

        public static PathfindingGrid CreateFromData(PathfindingGridData data)
        {
            if (data == null) return null;

            PathfindingGrid grid = new PathfindingGrid(data.Width, data.Height, data.CellSize, data.OriginPosition);
            if (data.BlockedCells != null)
            {
                foreach (var cell in data.BlockedCells)
                {
                    grid.SetWalkable(cell, false);
                }
            }

            return grid;
        }

        public void InitializeCells()
        {
            Cells = new GridCell[Width, Height];
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    Vector2 worldPos = GridToWorld(x, y, true);
                    Cells[x, y] = new GridCell(true, worldPos.x, worldPos.y);
                }
            }
        }

        public bool InBounds(int x, int y)
        {
            return x >= 0 && x < Width && y >= 0 && y < Height;
        }

        public bool InBounds(Vector2Int pos)
        {
            return InBounds(pos.x, pos.y);
        }

        public GridCell GetCell(int x, int y)
        {
            if (!InBounds(x, y)) return null;
            return Cells[x, y];
        }

        public GridCell GetCell(Vector2Int pos)
        {
            return GetCell(pos.x, pos.y);
        }

        public void SetWalkable(int x, int y, bool isWalkable)
        {
            if (InBounds(x, y))
            {
                Cells[x, y].IsWalkable = isWalkable;
            }
        }

        public void SetWalkable(Vector2Int pos, bool isWalkable)
        {
            SetWalkable(pos.x, pos.y, isWalkable);
        }

        public bool IsWalkable(int x, int y)
        {
            if (!InBounds(x, y)) return false;
            return Cells[x, y] != null && Cells[x, y].IsWalkable;
        }

        public bool IsWalkable(Vector2Int pos)
        {
            return IsWalkable(pos.x, pos.y);
        }

        public Vector2 GridToWorld(int x, int y, bool center = true)
        {
            float offset = center ? (CellSize * 0.5f) : 0f;
            return new Vector2(
                OriginPosition.x + x * CellSize + offset,
                OriginPosition.y + y * CellSize + offset
            );
        }

        public Vector2 GridToWorld(Vector2Int pos, bool center = true)
        {
            return GridToWorld(pos.x, pos.y, center);
        }

        public bool WorldToGrid(Vector2 worldPos, out Vector2Int gridPos)
        {
            int x = Mathf.FloorToInt((worldPos.x - OriginPosition.x) / CellSize);
            int y = Mathf.FloorToInt((worldPos.y - OriginPosition.y) / CellSize);

            gridPos = new Vector2Int(x, y);
            return InBounds(x, y);
        }

        public void ScanColliders(LayerMask obstacleLayer, float scale = 0.85f)
        {
            Vector2 boxSize = Vector2.one * (CellSize * Mathf.Clamp01(scale));

            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    Vector2 center = GridToWorld(x, y, true);
                    Collider2D hit = Physics2D.OverlapBox(center, boxSize, 0f, obstacleLayer);
                    Cells[x, y].IsWalkable = (hit == null);
                }
            }
        }
    }
}
