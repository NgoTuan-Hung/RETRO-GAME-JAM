using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    public Transform playerTransform;
    public Transform djTransform;

    private void Awake()
    {
        Instance = this;
    }
}