using System.Collections;
using UnityEngine;


public class PlayerTalk : MonoBehaviour
{
    private DialogSystem dialogSystem;

    // Use this for initialization
    void Start()
    {
        dialogSystem = FindAnyObjectByType<DialogSystem>();
        if (dialogSystem == null)
        {
            Debug.LogError("Dialog System Not Found!");
        }
        else
        {
            Debug.Log("DialogSystem found: " + dialogSystem.name);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (UnityEngine.InputSystem.Keyboard.current.tKey.wasPressedThisFrame)
        {
            dialogSystem.ShowDialog("Player", "Hello World!");
        }
    }
}
