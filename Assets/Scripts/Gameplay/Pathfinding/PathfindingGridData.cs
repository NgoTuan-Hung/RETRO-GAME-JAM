using System.Collections.Generic;
using UnityEngine;

namespace Gameplay.Pathfinding
{
    [CreateAssetMenu(fileName = "NewPathfindingGridData", menuName = "Pathfinding/Grid Data Asset", order = 1)]
    public class PathfindingGridData : ScriptableObject
    {
        [Header("Grid Dimensions & Position")]
        [Min(1)]
        [SerializeField] private int width = 16;
        [Min(1)]
        [SerializeField] private int height = 12;
        [Min(0.01f)]
        [SerializeField] private float cellSize = 1.0f;
        [SerializeField] private Vector2 originPosition = Vector2.zero;

        [Header("Obstacles")]
        [SerializeField] private List<Vector2Int> blockedCells = new List<Vector2Int>();

        public int Width => width;
        public int Height => height;
        public float CellSize => cellSize;
        public Vector2 OriginPosition => originPosition;
        public IReadOnlyList<Vector2Int> BlockedCells => blockedCells;

        public void SetData(int width, int height, float cellSize, Vector2 originPosition, IEnumerable<Vector2Int> obstacles)
        {
            this.width = Mathf.Max(1, width);
            this.height = Mathf.Max(1, height);
            this.cellSize = Mathf.Max(0.01f, cellSize);
            this.originPosition = originPosition;

            blockedCells.Clear();
            if (obstacles != null)
            {
                blockedCells.AddRange(obstacles);
            }
        }
    }
}
