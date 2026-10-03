using Gameplay.Player;
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    [SerializeField]
    private InputReader inputReader;
    private Rigidbody2D rb2d;
    [SerializeField]
    private float moveSpeed = 5f;

    private void Awake()
    {
        rb2d = GetComponent<Rigidbody2D>();
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }

    void FixedUpdate()
    {
        rb2d.linearVelocity = inputReader.MovementValue * moveSpeed;
        transform.localScale = new(inputReader.MovementValue.x < 0 ? -1 : 1, 1, 1);
    }
}
