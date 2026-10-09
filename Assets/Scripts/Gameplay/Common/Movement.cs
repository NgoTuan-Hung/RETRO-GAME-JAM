using UnityEngine;

namespace Gameplay.Common
{
    [DefaultExecutionOrder(1)]
    public class Movement : MonoBehaviour
    {
        private EntityComponentBase entityComponentBase;

        [SerializeField]
        private float moveSpeed = 5f;
        private float movementMagnitude;
        public Vector2 MovementValue { get; private set; }

        private void Awake()
        {
            entityComponentBase = GetComponent<EntityComponentBase>();
        }

        // Start is called once before the first execution of Update after the MonoBehaviour is created
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            movementMagnitude = MovementValue.magnitude;
            if (movementMagnitude > 0)
            {
                entityComponentBase.TurnOnFootstepAudio();
            }
            else
            {
                entityComponentBase.TurnOffFootstepAudio();
            }

            if (MovementValue.x != 0)
            {
                transform.localScale = new(MovementValue.x < 0 ? -1 : 1, 1, 1);
            }
            entityComponentBase.Animator.SetFloat("Speed", Mathf.Abs(movementMagnitude));
        }

        void FixedUpdate()
        {
            entityComponentBase.Rb2d.linearVelocity = MovementValue * moveSpeed;
        }

        public void SetMovementValue(Vector2 movement)
        {
            MovementValue = movement;
        }
    }
}