using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    public Transform playerTransform;
    public Transform djTransform;
    // Objects with SpriteRenderer in children
    public List<string> objectsWithSpriteRendererInChildren = new() { "Ghost" };

    private void Awake()
    {
        Instance = this;
    }

    public bool IsObjectWithSpriteRendererInChildren(GameObject obj)
    {
        foreach (var name in objectsWithSpriteRendererInChildren)
        {
            if (obj.name.Contains(name))
            {
                return true;
            }
        }
        return false;
    }
}