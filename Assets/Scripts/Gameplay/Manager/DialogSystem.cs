using TMPro;
using UnityEngine;

public class DialogSystem : MonoBehaviour
{

    [SerializeField] private TextMeshProUGUI dialogText;

    public void ShowDialog(string speaker, string text)
    {
        Debug.Log(speaker + " : " + text);

        dialogText.text = text;
        dialogText.gameObject.SetActive(true);
        Invoke(nameof(HideDialog), 5f);
    }

    void HideDialog()
    {
        dialogText.gameObject.SetActive(false);
    }
}
