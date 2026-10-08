using UnityEngine;

public class DialogSystem : MonoBehaviour
{
    public void ShowDialog(string speaker, string text)
    {
        Debug.Log(speaker + " : " + text);
    }
}
