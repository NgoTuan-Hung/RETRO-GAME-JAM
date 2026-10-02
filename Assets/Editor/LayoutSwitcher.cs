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
        // Đường dẫn tương đối tới 2 file layout bạn đã lưu
        private const string SCENE_GAME_LAYOUT = "Assets/Editor/Layouts/SceneGame.wlt";
        private const string SCENE_ONLY_LAYOUT = "Assets/Editor/Layouts/SceneOnly.wlt";

        private const string PREF_KEY = "RetroHorror_CurrentLayoutToggle";

        /// <summary>
        /// Phím tắt F12 để chuyển đổi qua lại giữa 2 layout
        /// Có thể tuỳ chỉnh lại phím trong Unity: Edit > Shortcuts > Layout > Toggle Scene & Game Layout
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
                Debug.LogError($"[LayoutSwitcher] Không tìm thấy file layout tại: {fullPath}");
                return;
            }

            Type windowLayoutType = typeof(EditorApplication).Assembly.GetType("UnityEditor.WindowLayout");
            if (windowLayoutType == null)
            {
                Debug.LogError("[LayoutSwitcher] Không tìm thấy class UnityEditor.WindowLayout.");
                return;
            }

            // 1. Thử TryLoadWindowLayout(string path, bool newProjectLayoutWasCreated) - Thường dùng trên Unity 6
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
                Debug.Log($"[LayoutSwitcher] Đã chuyển sang layout: {Path.GetFileNameWithoutExtension(relativePath)} (Result: {result})");
                return;
            }

            // 2. Thử LoadWindowLayout(string, bool, bool, bool, bool) - Unity 6 overload
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
                Debug.Log($"[LayoutSwitcher] Đã chuyển sang layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            // 3. Thử LoadWindowLayout(string, bool) - Unity 2021/2022
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
                Debug.Log($"[LayoutSwitcher] Đã chuyển sang layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            // 4. Thử LoadWindowLayout(string) - Các bản cũ hơn
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
                Debug.Log($"[LayoutSwitcher] Đã chuyển sang layout: {Path.GetFileNameWithoutExtension(relativePath)}");
                return;
            }

            Debug.LogError("[LayoutSwitcher] Không tìm thấy method load layout phù hợp trong UnityEditor.WindowLayout.");
        }
    }
}
#endif
