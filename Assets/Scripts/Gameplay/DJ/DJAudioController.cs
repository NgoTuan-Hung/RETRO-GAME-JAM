using FMOD.Studio;
using FMODUnity;
using UnityEngine;

namespace Gameplay.DJ
{
    public class DJAudioController : MonoBehaviour
    {
        [SerializeField] private EventReference musicEvent;

        [SerializeField] private float maxDistance = 20f;

        [SerializeField] private string proximityParamName = "Proximity from Basement or Attic Entrance to the Attic and Basement";

        private EventInstance musicInstance;

        void Start()
        {
            musicInstance = RuntimeManager.CreateInstance(musicEvent);
            RuntimeManager.AttachInstanceToGameObject(musicInstance, GameManager.Instance.djTransform.gameObject);
            musicInstance.start();
        }

        private void Update()
        {
            float distance = Vector3.Distance(GameManager.Instance.playerTransform.position, GameManager.Instance.djTransform.position);
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