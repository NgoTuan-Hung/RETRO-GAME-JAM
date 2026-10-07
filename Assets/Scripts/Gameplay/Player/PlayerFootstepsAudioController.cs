using FMOD.Studio;
using FMODUnity;
using UnityEngine;

namespace Gameplay.Player
{
    public class PlayerFootstepsAudioController : MonoBehaviour
    {
        public static PlayerFootstepsAudioController Instance { get; private set; }
        [SerializeField] private EventReference musicEvent;
        private EventInstance musicInstance;
        [SerializeField] private string isWalkingParamName = "IsWalking";
        [SerializeField] private string proximityParamName = "Proximity from Basement or Attic Entrance to the Attic and Basement";

        private void Awake()
        {
            Instance = this;
        }

        void Start()
        {
            musicInstance = RuntimeManager.CreateInstance(musicEvent);
            RuntimeManager.AttachInstanceToGameObject(musicInstance, GameManager.Instance.playerTransform.gameObject);
            musicInstance.setParameterByName(proximityParamName, 1f);
            musicInstance.start();
        }

        private void Update()
        {

        }

        public void TurnOnFootstepsAudio()
        {
            musicInstance.setParameterByName(isWalkingParamName, 1f);
        }

        public void TurnOffFootstepsAudio()
        {
            musicInstance.setParameterByName(isWalkingParamName, 0f);
        }

        private void OnDestroy()
        {
            musicInstance.stop(FMOD.Studio.STOP_MODE.IMMEDIATE);
            musicInstance.release();
        }
    }
}