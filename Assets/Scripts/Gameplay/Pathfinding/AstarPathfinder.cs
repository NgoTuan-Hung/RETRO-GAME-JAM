using System.Collections.Generic;
using UnityEngine;

namespace Gameplay.Pathfinding
{
    public static class AStarPathfinder
    {
        private const int StraightCost = 10;
        private const int DiagonalCost = 14;

        private static readonly Vector2Int[] Directions =
        {
            Vector2Int.up,
            Vector2Int.down,
            Vector2Int.left,
            Vector2Int.right,

            new Vector2Int( 1,  1),
            new Vector2Int( 1, -1),
            new Vector2Int(-1,  1),
            new Vector2Int(-1, -1)
        };

        // grid[x, y]: cell at coordinates (x, y).
        // Null cells are considered unwalkable.
        // The path includes both start and goal.
        // Returns null if no path is found.
        public static List<Vector2Int> FindPath(
            GridCell[,] grid,
            Vector2Int start,
            Vector2Int goal)
        {
            if (grid == null)
                return null;

            int width = grid.GetLength(0);
            int height = grid.GetLength(1);

            if (!InBounds(start, width, height) ||
                !InBounds(goal, width, height))
            {
                return null;
            }

            if (!IsWalkable(grid, start) ||
                !IsWalkable(grid, goal))
            {
                return null;
            }

            var open = new List<Vector2Int>();
            var inOpen = new bool[width, height];
            var closed = new bool[width, height];
            var gCost = new int[width, height];
            var parent = new Vector2Int[width, height];

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    gCost[x, y] = int.MaxValue;
                }
            }

            gCost[start.x, start.y] = 0;
            open.Add(start);
            inOpen[start.x, start.y] = true;

            while (open.Count > 0)
            {
                // Select the cell with the lowest fCost.
                // If equal, prioritize the one with lower hCost.
                int bestIndex = 0;

                for (int i = 1; i < open.Count; i++)
                {
                    Vector2Int candidate = open[i];
                    Vector2Int best = open[bestIndex];

                    int candidateH = Heuristic(candidate, goal);
                    int bestH = Heuristic(best, goal);

                    int candidateF =
                        gCost[candidate.x, candidate.y] + candidateH;

                    int bestF =
                        gCost[best.x, best.y] + bestH;

                    if (candidateF < bestF ||
                        (candidateF == bestF && candidateH < bestH))
                    {
                        bestIndex = i;
                    }
                }

                Vector2Int current = open[bestIndex];

                if (current == goal)
                    return ReconstructPath(parent, start, goal);

                open.RemoveAt(bestIndex);
                inOpen[current.x, current.y] = false;
                closed[current.x, current.y] = true;

                foreach (Vector2Int direction in Directions)
                {
                    Vector2Int next = current + direction;

                    if (!InBounds(next, width, height))
                        continue;

                    if (!IsWalkable(grid, next) ||
                        closed[next.x, next.y])
                    {
                        continue;
                    }

                    bool isDiagonal =
                        direction.x != 0 && direction.y != 0;

                    // Prevent cutting corners through obstacles.
                    // Both adjacent horizontal and vertical cells must be walkable.
                    if (isDiagonal)
                    {
                        Vector2Int horizontal = new Vector2Int(
                            current.x + direction.x,
                            current.y);

                        Vector2Int vertical = new Vector2Int(
                            current.x,
                            current.y + direction.y);

                        // These two cells are within grid bounds because current
                        // and next are both already within grid bounds.
                        if (!IsWalkable(grid, horizontal) ||
                            !IsWalkable(grid, vertical))
                        {
                            continue;
                        }
                    }

                    int stepCost = isDiagonal
                        ? DiagonalCost
                        : StraightCost;

                    int tentativeG =
                        gCost[current.x, current.y] + stepCost;

                    if (tentativeG >= gCost[next.x, next.y])
                        continue;

                    gCost[next.x, next.y] = tentativeG;
                    parent[next.x, next.y] = current;

                    if (!inOpen[next.x, next.y])
                    {
                        open.Add(next);
                        inOpen[next.x, next.y] = true;
                    }
                }
            }

            return null;
        }

        // Only call with coordinates already within grid bounds.
        private static bool IsWalkable(
            GridCell[,] grid,
            Vector2Int position)
        {
            GridCell cell = grid[position.x, position.y];
            return cell != null && cell.IsWalkable;
        }

        private static int Heuristic(Vector2Int a, Vector2Int b)
        {
            // Octile distance for 8-directional movement.
            int dx = Mathf.Abs(a.x - b.x);
            int dy = Mathf.Abs(a.y - b.y);

            int diagonalSteps = Mathf.Min(dx, dy);
            int straightSteps = Mathf.Max(dx, dy) - diagonalSteps;

            return diagonalSteps * DiagonalCost +
                   straightSteps * StraightCost;
        }

        private static bool InBounds(
            Vector2Int position,
            int width,
            int height)
        {
            return position.x >= 0 && position.x < width &&
                   position.y >= 0 && position.y < height;
        }

        private static List<Vector2Int> ReconstructPath(
            Vector2Int[,] parent,
            Vector2Int start,
            Vector2Int goal)
        {
            var path = new List<Vector2Int>();
            Vector2Int current = goal;

            while (current != start)
            {
                path.Add(current);
                current = parent[current.x, current.y];
            }

            path.Add(start);
            path.Reverse();

            return path;
        }
    }
}