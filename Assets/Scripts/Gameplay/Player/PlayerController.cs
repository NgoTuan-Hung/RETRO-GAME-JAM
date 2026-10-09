using Gameplay.Common;
using Gameplay.Player;
using UnityEngine;

[DefaultExecutionOrder(0)]
public class PlayerController : MonoBehaviour
{
    [SerializeField]
    private InputReader inputReader;
    private EntityComponentBase entityComponentBase;

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
        entityComponentBase.Movement.SetMovementValue(inputReader.MovementValue);
    }
}
