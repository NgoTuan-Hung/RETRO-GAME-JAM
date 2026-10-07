#if UNITY_EDITOR
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Animations;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace RetroHorror.EditorTools
{
    public static class NPCSetupHelper
    {
        public static void Execute()
        {
            Debug.Log("Starting NPC2 and NPC3 setup...");

            // 1. Create animation directories if needed
            if (!AssetDatabase.IsValidFolder("Assets/Animation/NPC2"))
            {
                AssetDatabase.CreateFolder("Assets/Animation", "NPC2");
            }
            if (!AssetDatabase.IsValidFolder("Assets/Animation/NPC3"))
            {
                AssetDatabase.CreateFolder("Assets/Animation", "NPC3");
            }

            // 2. Load sprites
            var npc2Sprites = LoadSprites("Assets/Texture/npc2.png");
            var npc3Sprites = LoadSprites("Assets/Texture/npc3.png");

            // 3. Create Animation Clips for NPC2
            var npc2Idle = CreateClip("Assets/Animation/NPC2/Idle.anim", "Idle", 1f, new (float, Sprite)[]
            {
                (0f, npc2Sprites["npc2_0"])
            });

            var npc2Walk = CreateClip("Assets/Animation/NPC2/Walking.anim", "Walking", 4f, new (float, Sprite)[]
            {
                (0f, npc2Sprites["npc2_1"]),
                (0.25f, npc2Sprites["npc2_2"]),
                (0.5f, npc2Sprites["npc2_3"]),
                (0.75f, npc2Sprites["npc2_4"])
            });

            var npc2Dance = CreateClip("Assets/Animation/NPC2/Dancing.anim", "Dancing", 2f, new (float, Sprite)[]
            {
                (0f, npc2Sprites["npc2_5"]),
                (0.5f, npc2Sprites["npc2_6"])
            });

            // 4. Create Animation Clips for NPC3
            var npc3Idle = CreateClip("Assets/Animation/NPC3/Idle.anim", "Idle", 1f, new (float, Sprite)[]
            {
                (0f, npc3Sprites["npc3_0"])
            });

            var npc3Walk = CreateClip("Assets/Animation/NPC3/Walking.anim", "Walking", 4f, new (float, Sprite)[]
            {
                (0f, npc3Sprites["npc3_1"]),
                (0.25f, npc3Sprites["npc3_2"]),
                (0.5f, npc3Sprites["npc3_3"]),
                (0.75f, npc3Sprites["npc3_4"])
            });

            var npc3Dance = CreateClip("Assets/Animation/NPC3/Dancing.anim", "Dancing", 2f, new (float, Sprite)[]
            {
                (0f, npc3Sprites["npc3_5"]),
                (0.5f, npc3Sprites["npc3_6"])
            });

            // 5. Create Animator Controllers
            var npc2Controller = CreateController("Assets/Animation/NPC2/NPC2.controller", "NPC2", npc2Dance, npc2Walk, npc2Idle);
            var npc3Controller = CreateController("Assets/Animation/NPC3/NPC3.controller", "NPC3", npc3Dance, npc3Walk, npc3Idle);

            // 6. Ensure NPC1 in scene exists and duplicate to create NPC2 and NPC3
            GameObject npc1 = GameObject.Find("NPC1");
            if (npc1 == null)
            {
                Debug.LogError("NPC1 not found in hierarchy!");
                return;
            }

            // NPC2
            GameObject npc2 = GameObject.Find("NPC2");
            if (npc2 == null)
            {
                npc2 = Object.Instantiate(npc1);
                npc2.name = "NPC2";
                Undo.RegisterCreatedObjectUndo(npc2, "Create NPC2");
            }
            npc2.transform.position = new Vector3(-10f, -1.1f, 0f);
            var sr2 = npc2.GetComponent<SpriteRenderer>();
            if (sr2 != null)
            {
                Undo.RecordObject(sr2, "Set NPC2 Sprite");
                sr2.sprite = npc2Sprites["npc2_0"];
                var so2 = new SerializedObject(sr2);
                so2.FindProperty("m_Sprite").objectReferenceValue = npc2Sprites["npc2_0"];
                so2.ApplyModifiedProperties();
                EditorUtility.SetDirty(sr2);
            }
            var anim2 = npc2.GetComponent<Animator>();
            if (anim2 != null)
            {
                Undo.RecordObject(anim2, "Set NPC2 Animator");
                anim2.runtimeAnimatorController = npc2Controller;
                EditorUtility.SetDirty(anim2);
            }

            // NPC3
            GameObject npc3 = GameObject.Find("NPC3");
            if (npc3 == null)
            {
                npc3 = Object.Instantiate(npc1);
                npc3.name = "NPC3";
                Undo.RegisterCreatedObjectUndo(npc3, "Create NPC3");
            }
            npc3.transform.position = new Vector3(48f, -1.1f, 0f);
            var sr3 = npc3.GetComponent<SpriteRenderer>();
            if (sr3 != null)
            {
                Undo.RecordObject(sr3, "Set NPC3 Sprite");
                sr3.sprite = npc3Sprites["npc3_0"];
                var so3 = new SerializedObject(sr3);
                so3.FindProperty("m_Sprite").objectReferenceValue = npc3Sprites["npc3_0"];
                so3.ApplyModifiedProperties();
                EditorUtility.SetDirty(sr3);
            }
            var anim3 = npc3.GetComponent<Animator>();
            if (anim3 != null)
            {
                Undo.RecordObject(anim3, "Set NPC3 Animator");
                anim3.runtimeAnimatorController = npc3Controller;
                EditorUtility.SetDirty(anim3);
            }

            EditorUtility.SetDirty(npc2);
            EditorUtility.SetDirty(npc3);
            EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
            EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene());

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("NPC2 and NPC3 setup completed successfully!");
        }

        private static Dictionary<string, Sprite> LoadSprites(string path)
        {
            var dict = new Dictionary<string, Sprite>();
            var allAssets = AssetDatabase.LoadAllAssetsAtPath(path);
            foreach (var asset in allAssets)
            {
                if (asset is Sprite s)
                {
                    dict[s.name] = s;
                }
            }
            return dict;
        }

        private static AnimationClip CreateClip(string path, string name, float sampleRate, (float time, Sprite sprite)[] frames)
        {
            AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(path);
            if (clip == null)
            {
                clip = new AnimationClip();
                clip.name = name;
                AssetDatabase.CreateAsset(clip, path);
            }

            clip.frameRate = sampleRate;

            var binding = new EditorCurveBinding
            {
                type = typeof(SpriteRenderer),
                path = "",
                propertyName = "m_Sprite"
            };

            var keyframes = new ObjectReferenceKeyframe[frames.Length];
            for (int i = 0; i < frames.Length; i++)
            {
                keyframes[i] = new ObjectReferenceKeyframe
                {
                    time = frames[i].time,
                    value = frames[i].sprite
                };
            }

            AnimationUtility.SetObjectReferenceCurve(clip, binding, keyframes);

            var settings = AnimationUtility.GetAnimationClipSettings(clip);
            settings.loopTime = true;
            AnimationUtility.SetAnimationClipSettings(clip, settings);

            EditorUtility.SetDirty(clip);
            return clip;
        }

        private static AnimatorController CreateController(string path, string name, AnimationClip danceClip, AnimationClip walkClip, AnimationClip idleClip)
        {
            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(path);
            if (controller == null)
            {
                controller = AnimatorController.CreateAnimatorControllerAtPath(path);
            }

            var rootStateMachine = controller.layers[0].stateMachine;

            // Clear old states if any to ensure clean setup
            var childStates = rootStateMachine.states;
            foreach (var childState in childStates)
            {
                rootStateMachine.RemoveState(childState.state);
            }

            var dancingState = rootStateMachine.AddState("Dancing", new Vector3(320, 120, 0));
            dancingState.motion = danceClip;

            var walkingState = rootStateMachine.AddState("Walking", new Vector3(360, 180, 0));
            walkingState.motion = walkClip;

            var idleState = rootStateMachine.AddState("Idle", new Vector3(360, 240, 0));
            idleState.motion = idleClip;

            rootStateMachine.defaultState = dancingState;

            EditorUtility.SetDirty(controller);
            return controller;
        }
    }
}
#endif
