using UnityEngine;

namespace Gameplay.Pathfinding
{
    public class GridCell
    {
        public bool IsWalkable { get; set; }
        public float worldPositionX { get; set; }
        public float worldPositionY { get; set; }

        public GridCell(bool isWalkable, float worldPositionX, float worldPositionY)
        {
            IsWalkable = isWalkable;
            this.worldPositionX = worldPositionX;
            this.worldPositionY = worldPositionY;
        }
    }
}