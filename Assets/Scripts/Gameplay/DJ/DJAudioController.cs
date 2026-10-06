using FMOD.Studio;
using FMODUnity;
using UnityEngine;

namespace Gameplay.DJ
{
    public class DJAudioController : MonoBehaviour
    {
        [SerializeField] private EventReference musicEvent;

        [SerializeField] private Transform playerTransform;
        [SerializeField] private float maxDistance = 20f;

        [SerializeField] private string proximityParamName = "Proximity from Basement or Attic Entrance to the Attic and Basement";

        private EventInstance musicInstance;

        void Start()
        {
            musicInstance = RuntimeManager.CreateInstance(musicEvent);
            RuntimeManager.AttachInstanceToGameObject(musicInstance, gameObject);
            musicInstance.start();
        }

        private void Update()
        {
            float distance = Vector3.Distance(playerTransform.position, transform.position);
            float proximity = Mathf.Clamp01(distance / maxDistance);

            musicInstance.setParameterByName(proximityParamName, proximity);
        }

        private void OnDestroy()
        {
            musicInstance.stop(FMOD.Studio.STOP_MODE.IMMEDIATE);
            musicInstance.release();
        }
    }
}