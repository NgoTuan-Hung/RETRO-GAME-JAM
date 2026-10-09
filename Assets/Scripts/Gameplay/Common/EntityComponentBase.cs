using System;
using Gameplay.Player;
using UnityEngine;

namespace Gameplay.Common
{
    [RequireComponent(typeof(Rigidbody2D), typeof(Animator), typeof(Movement))]
    public class EntityComponentBase : MonoBehaviour
    {
        public Rigidbody2D Rb2d { get; private set; }
        public Animator Animator { get; private set; }
        public Action TurnOnFootstepAudio = () => { };
        public Action TurnOffFootstepAudio = () => { };
        public Movement Movement { get; private set; }

        protected virtual void Awake()
        {
            Rb2d = GetComponent<Rigidbody2D>();
            Animator = GetComponent<Animator>();
            Movement = GetComponent<Movement>();
        }

        private void Start()
        {
            SelectFootstepAudioLogic();
        }

        void SelectFootstepAudioLogic()
        {
            if (gameObject.name.Contains("Player"))
            {
                TurnOnFootstepAudio = () => PlayerFootstepsAudioController.Instance.TurnOnFootstepsAudio();
                TurnOffFootstepAudio = () => PlayerFootstepsAudioController.Instance.TurnOffFootstepsAudio();
            }
        }
    }
}