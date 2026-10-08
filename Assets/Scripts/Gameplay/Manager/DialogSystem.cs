using TMPro;
using Unity.VisualScripting;
using UnityEngine;

public class DialogSystem : MonoBehaviour
{
    private const string startText = "Night of the\r\nBoogie-Woogie Man\r\n\r\nWASD for movement\r\nT for Character Dialog";

    [SerializeField] private TextMeshProUGUI dialogText;
    [SerializeField] private RectTransform backgroundImage;

    void Start()
    {
        ShowDialog(null, startText);
        dialogText.gameObject.SetActive(true);
    }

    public void ShowDialog(string speaker, string text)
    {
        // Send text to the console
        Debug.Log(speaker + " : " + text);

        // Stop text from timing-out too early in response to earlier delayed HideDialog() calls
        CancelInvoke(nameof(HideDialog));
 
        // set the text
        dialogText.text = text;
        
        // Size background to fit text + 20px margin
        float width = dialogText.preferredWidth + 40f;
        float height = dialogText.preferredHeight + 40f;
        backgroundImage.sizeDelta = new Vector2(width, height);

        // Align background with text position
        backgroundImage.anchoredPosition = dialogText.rectTransform.anchoredPosition;

        // Show the background image and text
        backgroundImage.gameObject.SetActive(true);
        dialogText.gameObject.SetActive(true);

        // Calls HideDialog() after 5.00 seconds
        Invoke(nameof(HideDialog), 5f);
    }

    void HideDialog()
    {
        // hide the text and background image
        dialogText.gameObject.SetActive(false);
        backgroundImage.gameObject.SetActive(false);
    }
}
