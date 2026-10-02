using UnityEngine;

public class Alpha : MonoBehaviour
{
    string name;

    void Awake()
    {
        name = "Alpha";
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        transform.position = new Vector3(0, 0, 0);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
