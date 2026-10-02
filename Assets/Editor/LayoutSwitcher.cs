#if UNITY_EDITOR
using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.ShortcutManagement;
using UnityEngine;

namespace RetroHorror.EditorTools
{
    public static class LayoutSwitcher
    {
        // Relative paths to the two saved layout files
        private const string SCENE_GAME_LAYOUT = "Assets/Editor/Layouts/SceneGame.wlt";
        private const string SCENE_ONLY_LAYOUT = "Assets/Editor/Layouts/SceneOnly.wlt";

        private const string PREF_KEY = "RetroHorror_CurrentLayoutToggle";

        /// <summary>
        /// F12 shortcut to toggle between the two layouts
        /// The shortcut can be customized in Unity: Edit > Shortcuts > Layout > Toggle Scene & Game Layout
        /// </summary>
        [MenuItem("Window/Layouts/Toggle Scene & Game Layout _F12", priority = 999)]
        [Shortcut("Layout/Toggle Scene & Game Layout", KeyCode.F12)]
        public static void ToggleLayout()
        {
            // 0: SceneGame, 1: SceneOnly
            int currentState = EditorPrefs.GetInt(PREF_KEY, 0);

            if (currentState == 0)
            {
                LoadSceneOnly();
            }
            else
            {
                LoadSceneGame();
            }
        }

        [MenuItem("Window/Layouts/Quick Layout/1. Scene & Game", priority = 1000)]
        public static void LoadSceneGame()
        {
            EditorPrefs.SetInt(PREF_KEY, 0);
            ApplyLayout(SCENE_GAME_LAYOUT);
        }

        [MenuItem("Window/Layouts/Quick Layout/2. Scene Only", priority = 1001)]
        public static void LoadSceneOnly()
        {
            EditorPrefs.SetInt(PREF_KEY, 1);
            ApplyLayout(SCENE_ONLY_LAYOUT);
        }

        private static void ApplyLayout(string relativePath)
        {
            string fullPath = Path.Combine(Directory.GetCurrentDirectory(), relativePath);

            if (!File.Exists(fullPath))
            {
                Debug.LogError($"[LayoutSwitcher] Layout file not found at: {fullPath}");
                return;
            }

            Type windowLayoutType = typeof(EditorApplication).Assembly.GetType("UnityEditor.WindowLayout");
            if (windowLayoutType == null)
            {
                Debug.LogError("[LayoutSwitcher] UnityEditor.WindowLayout class not found.");
                return;
            }

            // 1. Try TryLoadWindowLayout(string path, bool newProjectLayoutWasCreated) - Commonly used in Unity 6
            MethodInfo method = windowLayoutType.GetMethod(
                "TryLoadWindowLayout",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new Type[] { typeof(string), typeof(bool) },
                null
            );

            if (method != null)
            {
                object result = method.Invoke(null, new object[] { fullPath, false });
                Debug.Log($"[LayoutSwitcher] Switched to layout: {Path.GetFileNameWithoutExtension(relativePath)} (Result: {result})");
                return;
            }

            // 2. Try LoadWindowLayout(string, bool, bool, bool, bool) - Unity 6 overload
            method = windowLayoutType.GetMethod(
                "LoadWindowLayout",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new Type[] { typeof(string), typeof(bool), typeof(bool), typeof(bool), typeof(bool) },
                null
            );

            if (method != null)
            {
                method.Invoke(null, new object[] { fullPath, false, true, false, true });
                Debug.Log($"[LayoutSwitcher] Switched to layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            // 3. Try LoadWindowLayout(string, bool) - Unity 2021/2022
            method = windowLayoutType.GetMethod(
                "LoadWindowLayout",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new Type[] { typeof(string), typeof(bool) },
                null
            );

            if (method != null)
            {
                method.Invoke(null, new object[] { fullPath, false });
                Debug.Log($"[LayoutSwitcher] Switched to layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            // 4. Try LoadWindowLayout(string) - Older versions
            method = windowLayoutType.GetMethod(
                "LoadWindowLayout",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new Type[] { typeof(string) },
                null
            );

            if (method != null)
            {
                method.Invoke(null, new object[] { fullPath });
                Debug.Log($"[LayoutSwitcher] Switched to layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            Debug.LogError("[LayoutSwitcher] Suitable layout loading method not found in UnityEditor.WindowLayout.");
        }
    }
}
#endif
