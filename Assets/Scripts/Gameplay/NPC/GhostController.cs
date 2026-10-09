using System;
using System.Collections.Generic;
using Gameplay.Common;
using Gameplay.Pathfinding;
using UnityEngine;

namespace Gameplay.NPC
{
    [RequireComponent(typeof(EntityComponentBase))]
    public class GhostController : MonoBehaviour
    {
        private EntityComponentBase entityComponentBase;
        Vector2 thisFrameDirection;
        public GameObject Target;
        [SerializeField] private float pathfindingInterval = 0.5f;
        private float timeSinceLastPathfinding = 0f;
        private List<Vector2> pathToTarget;
        private bool waitForNextPathfinding = false;
        private int currentCheckpointOnPath = 0;
        [SerializeField] private float nextCheckpointMinDist = 0.5f;
        private void Awake()
        {
            entityComponentBase = GetComponent<EntityComponentBase>();
        }

        private void Update()
        {
            if (Target == null) return;

            if (pathToTarget != null && !waitForNextPathfinding)
            {
                SelectNextCheckpointOnPath();
                DecideWhereToGoNext();
            }

            timeSinceLastPathfinding += Time.deltaTime;
            if (timeSinceLastPathfinding >= pathfindingInterval)
            {
                timeSinceLastPathfinding = 0f;
                UpdatePath();
            }
            entityComponentBase.Movement.SetMovementValue(thisFrameDirection);
        }

        private void DecideWhereToGoNext()
        {
            if (currentCheckpointOnPath >= pathToTarget.Count)
            {
                thisFrameDirection = Vector2.zero;
                return;
            }
            Vector2 nextPosition = pathToTarget[currentCheckpointOnPath];
            thisFrameDirection = (nextPosition - (Vector2)transform.position).normalized;
        }

        void SelectNextCheckpointOnPath()
        {
            if (Math.Abs(Vector2.Distance(transform.position, pathToTarget[currentCheckpointOnPath])) < nextCheckpointMinDist)
            {
                if (currentCheckpointOnPath < pathToTarget.Count - 1)
                {
                    currentCheckpointOnPath++;
                }
            }
        }

        void DecideWaitingOrNot()
        {
            if (pathToTarget == null || pathToTarget.Count <= 1)
            {
                waitForNextPathfinding = true;
            }
            else
            {
                waitForNextPathfinding = false;
            }
        }

        void UpdatePath()
        {
            pathToTarget = PathfindingManager.Instance.FindPath(transform.position, Target.transform.position);
            DecideWaitingOrNot();
            currentCheckpointOnPath = 0;
        }
    }
}