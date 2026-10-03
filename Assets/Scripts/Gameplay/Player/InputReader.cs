using UnityEngine;

namespace Gameplay.Player
{
    public class InputReader : MonoBehaviour
    {
        private GameInput gameInput;
        public Vector2 MovementValue { get; private set; }

        private void Awake()
        {
            gameInput = new();
        }

        private void OnEnable()
        {
            gameInput.Enable();

            gameInput.Movement.Move.performed += (ctx) => MovementValue = ctx.ReadValue<Vector2>();
            gameInput.Movement.Move.canceled += (ctx) => MovementValue = Vector2.zero;
        }

        private void OnDisable()
        {
            gameInput.Disable();
        }
    }
}