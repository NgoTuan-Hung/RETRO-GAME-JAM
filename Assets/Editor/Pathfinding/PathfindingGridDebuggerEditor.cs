using Gameplay.Pathfinding;
using UnityEditor;
using UnityEngine;

namespace Gameplay.Pathfinding.Editor
{
    [CustomEditor(typeof(PathfindingGridDebugger))]
    public class PathfindingGridDebuggerEditor : UnityEditor.Editor
    {
        private enum EditToolMode
        {
            View,
            SetStart,
            SetGoal,
            AddObstacle,
            RemoveObstacle
        }

        private enum DrawShapeMode
        {
            Pen,
            Box
        }

        private static EditToolMode currentMode = EditToolMode.View;
        private static DrawShapeMode currentDrawShape = DrawShapeMode.Pen;
        private PathfindingGridDebugger debugger;
        private Vector2Int lastHoveredCell = new Vector2Int(-1, -1);
        private Vector2Int lastPaintedCell = new Vector2Int(-1, -1);
        private bool isMouseInGrid = false;
        private bool isBoxDragging = false;
        private Vector2Int boxStartCell;
        private Vector2Int boxCurrentCell;

        private void OnEnable()
        {
            debugger = (PathfindingGridDebugger)target;
            if (debugger != null && debugger.Grid == null)
            {
                debugger.RebuildGrid();
            }
        }

        [MenuItem("GameObject/2D Object/Pathfinding Grid Debugger", false, 10)]
        [MenuItem("Tools/Pathfinding/Create Grid Debugger")]
        public static void CreateGridDebugger()
        {
            GameObject go = new GameObject("PathfindingGridDebugger");
            go.transform.position = Vector3.zero;
            var comp = go.AddComponent<PathfindingGridDebugger>();
            comp.RebuildGrid();

            Selection.activeGameObject = go;
            Undo.RegisterCreatedObjectUndo(go, "Create Pathfinding Grid Debugger");
        }

        public override void OnInspectorGUI()
        {
            debugger = (PathfindingGridDebugger)target;
            serializedObject.Update();

            EditorGUILayout.Space(5);
            EditorGUILayout.LabelField("Pathfinding Grid Debugger", EditorStyles.boldLabel);

            // Tool selection toolbar
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUILayout.LabelField("Scene Interaction Mode:", EditorStyles.miniBoldLabel);
            currentMode = (EditToolMode)GUILayout.Toolbar((int)currentMode, new string[]
            {
                "👁 View",
                "🟢 Start",
                "🎯 Goal",
                "🧱 Wall",
                "🧹 Erase"
            });

            if (currentMode == EditToolMode.AddObstacle || currentMode == EditToolMode.RemoveObstacle)
            {
                EditorGUILayout.Space(4);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Draw Style:", EditorStyles.miniBoldLabel, GUILayout.Width(75));
                currentDrawShape = (DrawShapeMode)GUILayout.Toolbar((int)currentDrawShape, new string[]
                {
                    "✏️ Pen (Brush)",
                    "📦 Box (Drag Area)"
                });
                EditorGUILayout.EndHorizontal();

                string helpText = currentDrawShape == DrawShapeMode.Box
                    ? "Drag a box in Scene view to paint/erase rectangular areas. (Hold Shift to switch temporarily)."
                    : "Click or drag freely in Scene view to paint/erase single cells. (Hold Shift to drag a box).";
                EditorGUILayout.HelpBox(helpText, MessageType.None);
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space(5);

            // Default serialized properties
            DrawDefaultInspector();

            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("Pathfinding Controls", EditorStyles.boldLabel);

            EditorGUILayout.BeginHorizontal();
            GUI.backgroundColor = new Color(0.4f, 1f, 0.4f);
            if (GUILayout.Button("▶ Find Path (A*)", GUILayout.Height(32)))
            {
                Undo.RecordObject(debugger, "Run A* Pathfinding");
                debugger.FindPath();
                SceneView.RepaintAll();
            }

            GUI.backgroundColor = new Color(0.9f, 0.9f, 0.4f);
            if (GUILayout.Button("🔍 Scan Colliders", GUILayout.Height(32)))
            {
                Undo.RecordObject(debugger, "Scan Physics Colliders");
                debugger.ScanPhysicsColliders();
                SceneView.RepaintAll();
            }
            EditorGUILayout.EndHorizontal();

            GUI.backgroundColor = Color.white;
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("🧹 Clear Obstacles"))
            {
                if (EditorUtility.DisplayDialog("Clear Obstacles", "Are you sure you want to clear all obstacles?", "Yes", "No"))
                {
                    Undo.RecordObject(debugger, "Clear Obstacles");
                    debugger.ClearObstacles();
                    SceneView.RepaintAll();
                }
            }

            if (GUILayout.Button("🔄 Reset Grid"))
            {
                Undo.RecordObject(debugger, "Reset Grid");
                debugger.RebuildGrid();
                SceneView.RepaintAll();
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("Grid Data Asset (Save / Load)", EditorStyles.boldLabel);

            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            SerializedProperty gridDataAssetProp = serializedObject.FindProperty("gridDataAsset");
            EditorGUILayout.PropertyField(gridDataAssetProp, new GUIContent("Target Asset"));

            PathfindingGridData currentAsset = debugger.GridDataAsset;

            EditorGUILayout.BeginHorizontal();
            if (currentAsset != null)
            {
                GUI.backgroundColor = new Color(0.3f, 0.8f, 1f);
                if (GUILayout.Button("💾 Save to Asset", GUILayout.Height(28)))
                {
                    debugger.SaveToDataAsset();
                    EditorUtility.SetDirty(currentAsset);
                    AssetDatabase.SaveAssets();
                }

                GUI.backgroundColor = new Color(1f, 0.85f, 0.3f);
                if (GUILayout.Button("📂 Load from Asset", GUILayout.Height(28)))
                {
                    if (EditorUtility.DisplayDialog("Load Grid", $"Load grid settings and obstacles from {currentAsset.name}? This will overwrite current changes in the debugger.", "Yes", "No"))
                    {
                        Undo.RecordObject(debugger, "Load Grid from Asset");
                        debugger.LoadFromDataAsset();
                        SceneView.RepaintAll();
                    }
                }
                GUI.backgroundColor = Color.white;
            }
            else
            {
                GUI.backgroundColor = new Color(0.4f, 0.9f, 0.4f);
                if (GUILayout.Button("➕ Create & Save New Grid Asset", GUILayout.Height(28)))
                {
                    CreateAndAssignNewGridAsset();
                }
                GUI.backgroundColor = Color.white;
            }
            EditorGUILayout.EndHorizontal();

            if (currentAsset != null)
            {
                EditorGUILayout.Space(2);
                if (GUILayout.Button("📄 Save As New Asset..."))
                {
                    CreateAndAssignNewGridAsset();
                }
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space(10);

            // Status display
            EditorGUILayout.LabelField("Status", EditorStyles.boldLabel);
            if (debugger.LastPathSearchSucceeded)
            {
                EditorGUILayout.HelpBox(debugger.LastSearchMessage, MessageType.Info);
            }
            else
            {
                EditorGUILayout.HelpBox(debugger.LastSearchMessage, MessageType.Warning);
            }

            EditorGUILayout.LabelField($"Total Obstacles: {debugger.ObstacleCount}", EditorStyles.miniLabel);

            serializedObject.ApplyModifiedProperties();
        }

        private void CreateAndAssignNewGridAsset()
        {
            string defaultName = $"{debugger.gameObject.scene.name}_GridData";
            if (string.IsNullOrEmpty(debugger.gameObject.scene.name)) defaultName = "NewPathfindingGridData";

            string path = EditorUtility.SaveFilePanelInProject(
                "Save Pathfinding Grid Data",
                defaultName,
                "asset",
                "Choose where to save the Pathfinding Grid Data asset."
            );

            if (!string.IsNullOrEmpty(path))
            {
                PathfindingGridData newAsset = ScriptableObject.CreateInstance<PathfindingGridData>();
                newAsset.SetData(debugger.Width, debugger.Height, debugger.CellSize, debugger.WorldOrigin, debugger.ManualObstacles);
                AssetDatabase.CreateAsset(newAsset, path);
                AssetDatabase.SaveAssets();

                SerializedProperty gridDataAssetProp = serializedObject.FindProperty("gridDataAsset");
                gridDataAssetProp.objectReferenceValue = newAsset;
                serializedObject.ApplyModifiedProperties();

                EditorGUIUtility.PingObject(newAsset);
                Debug.Log($"[PathfindingGridDebugger] Created and assigned new Grid Data asset at: {path}");
            }
        }

        private void OnSceneGUI()
        {
            debugger = (PathfindingGridDebugger)target;
            if (debugger == null || debugger.Grid == null) return;

            Event current = Event.current;
            float toolbarHeight = (currentMode == EditToolMode.AddObstacle || currentMode == EditToolMode.RemoveObstacle) ? 190f : 160f;
            Rect toolbarRect = new Rect(10, 10, 240, toolbarHeight);

            Ray mouseRay = HandleUtility.GUIPointToWorldRay(current.mousePosition);
            Vector2 mouseWorld = new Vector2(mouseRay.origin.x, mouseRay.origin.y);

            int rawGridX = Mathf.FloorToInt((mouseWorld.x - debugger.WorldOrigin.x) / debugger.CellSize);
            int rawGridY = Mathf.FloorToInt((mouseWorld.y - debugger.WorldOrigin.y) / debugger.CellSize);
            Vector2Int rawGridPos = new Vector2Int(rawGridX, rawGridY);

            isMouseInGrid = !toolbarRect.Contains(current.mousePosition) && debugger.Grid.InBounds(rawGridPos);
            Vector2Int clampedCell = new Vector2Int(
                Mathf.Clamp(rawGridX, 0, debugger.Width - 1),
                Mathf.Clamp(rawGridY, 0, debugger.Height - 1)
            );

            if (isMouseInGrid)
            {
                lastHoveredCell = clampedCell;
            }

            // Draw floating Scene GUI Toolbar
            DrawSceneViewToolbar(toolbarRect);

            // Draw labels for Start and Goal points
            Vector2 startWorld = debugger.Grid.GridToWorld(debugger.StartPoint, true);
            Vector2 endWorld = debugger.Grid.GridToWorld(debugger.EndPoint, true);

            GUIStyle labelStyle = new GUIStyle(EditorStyles.boldLabel)
            {
                normal = { textColor = Color.white },
                alignment = TextAnchor.MiddleCenter,
                fontSize = 11
            };

            Handles.Label(startWorld + Vector2.up * (debugger.CellSize * 0.6f), "START", labelStyle);
            Handles.Label(endWorld + Vector2.up * (debugger.CellSize * 0.6f), "GOAL", labelStyle);

            bool effectiveBoxMode = (currentDrawShape == DrawShapeMode.Box) ^ current.shift;

            // Draw Box preview if dragging
            if (isBoxDragging)
            {
                int minX = Mathf.Min(boxStartCell.x, boxCurrentCell.x);
                int maxX = Mathf.Max(boxStartCell.x, boxCurrentCell.x);
                int minY = Mathf.Min(boxStartCell.y, boxCurrentCell.y);
                int maxY = Mathf.Max(boxStartCell.y, boxCurrentCell.y);
                int countX = maxX - minX + 1;
                int countY = maxY - minY + 1;
                int totalCells = countX * countY;

                Vector2 bottomLeft = debugger.Grid.GridToWorld(minX, minY, false);
                Vector2 boxWorldSize = new Vector2(countX * debugger.CellSize, countY * debugger.CellSize);
                Vector2 boxCenter = bottomLeft + boxWorldSize * 0.5f;

                bool isAdding = (currentMode == EditToolMode.AddObstacle);
                Color fillColor = isAdding
                    ? new Color(1f, 0.15f, 0.15f, 0.35f)
                    : new Color(1f, 0.9f, 0.1f, 0.35f);
                Color outlineColor = isAdding
                    ? new Color(1f, 0.25f, 0.25f, 0.95f)
                    : new Color(1f, 0.95f, 0.2f, 0.95f);

                Vector3[] verts = new Vector3[]
                {
                    new Vector3(bottomLeft.x, bottomLeft.y, 0f),
                    new Vector3(bottomLeft.x + boxWorldSize.x, bottomLeft.y, 0f),
                    new Vector3(bottomLeft.x + boxWorldSize.x, bottomLeft.y + boxWorldSize.y, 0f),
                    new Vector3(bottomLeft.x, bottomLeft.y + boxWorldSize.y, 0f)
                };

                Handles.DrawSolidRectangleWithOutline(verts, fillColor, outlineColor);

                if (countX <= 40 && countY <= 40)
                {
                    Handles.color = new Color(outlineColor.r, outlineColor.g, outlineColor.b, 0.35f);
                    Vector3 cellWireSize = new Vector3(debugger.CellSize * 0.95f, debugger.CellSize * 0.95f, 0f);
                    for (int x = minX; x <= maxX; x++)
                    {
                        for (int y = minY; y <= maxY; y++)
                        {
                            Vector2 cellCenter = debugger.Grid.GridToWorld(x, y, true);
                            Handles.DrawWireCube(cellCenter, cellWireSize);
                        }
                    }
                }

                string actionText = isAdding ? "PAINT WALLS" : "ERASE WALLS";
                string boxInfo = $"{actionText}\n{countX} × {countY} ({totalCells} cells)\n[{minX}, {minY}] → [{maxX}, {maxY}]";
                GUIStyle boxLabelStyle = new GUIStyle(EditorStyles.boldLabel)
                {
                    normal = { textColor = Color.white },
                    alignment = TextAnchor.MiddleCenter,
                    fontSize = 11
                };
                Handles.Label(boxCenter, boxInfo, boxLabelStyle);
            }
            else if (isMouseInGrid)
            {
                // Highlight hovered cell
                Vector2 cellCenter = debugger.Grid.GridToWorld(clampedCell, true);
                Vector3 boxSize = new Vector3(debugger.CellSize * 0.95f, debugger.CellSize * 0.95f, 0f);

                Color hoverColor = currentMode switch
                {
                    EditToolMode.SetStart => new Color(0f, 1f, 0.2f, 0.5f),
                    EditToolMode.SetGoal => new Color(0f, 0.7f, 1f, 0.5f),
                    EditToolMode.AddObstacle => effectiveBoxMode ? new Color(1f, 0.3f, 0.3f, 0.65f) : new Color(1f, 0.2f, 0.2f, 0.5f),
                    EditToolMode.RemoveObstacle => effectiveBoxMode ? new Color(1f, 0.95f, 0.2f, 0.65f) : new Color(1f, 1f, 0f, 0.5f),
                    _ => new Color(1f, 1f, 1f, 0.3f)
                };

                Handles.color = hoverColor;
                Handles.DrawWireCube(cellCenter, boxSize);

                string hint = (effectiveBoxMode && (currentMode == EditToolMode.AddObstacle || currentMode == EditToolMode.RemoveObstacle))
                    ? $"({clampedCell.x},{clampedCell.y}) [Drag Box]"
                    : $"({clampedCell.x},{clampedCell.y})";

                Handles.Label(cellCenter - Vector2.up * (debugger.CellSize * 0.45f), hint, EditorStyles.miniLabel);
            }

            // Handle Mouse Interactions based on EditToolMode
            int controlID = GUIUtility.GetControlID(FocusType.Passive);
            if (currentMode != EditToolMode.View)
            {
                HandleUtility.AddDefaultControl(controlID);
            }

            // Cancel box dragging on Escape
            if (current.type == EventType.KeyDown && current.keyCode == KeyCode.Escape && isBoxDragging)
            {
                isBoxDragging = false;
                if (GUIUtility.hotControl == controlID)
                {
                    GUIUtility.hotControl = 0;
                }
                current.Use();
                SceneView.RepaintAll();
            }

            if (currentMode != EditToolMode.View)
            {
                // MouseDown
                if (current.type == EventType.MouseDown && current.button == 0 && (isMouseInGrid || isBoxDragging))
                {
                    GUIUtility.hotControl = controlID;

                    switch (currentMode)
                    {
                        case EditToolMode.SetStart:
                            Undo.RecordObject(debugger, "Set Start Point");
                            debugger.SetStartPoint(clampedCell);
                            EditorUtility.SetDirty(debugger);
                            break;

                        case EditToolMode.SetGoal:
                            Undo.RecordObject(debugger, "Set Goal Point");
                            debugger.SetEndPoint(clampedCell);
                            EditorUtility.SetDirty(debugger);
                            break;

                        case EditToolMode.AddObstacle:
                        case EditToolMode.RemoveObstacle:
                            if (effectiveBoxMode)
                            {
                                isBoxDragging = true;
                                boxStartCell = clampedCell;
                                boxCurrentCell = clampedCell;
                            }
                            else
                            {
                                Undo.RecordObject(debugger, currentMode == EditToolMode.AddObstacle ? "Add Obstacle" : "Remove Obstacle");
                                if (currentMode == EditToolMode.AddObstacle)
                                    debugger.AddObstacle(clampedCell);
                                else
                                    debugger.RemoveObstacle(clampedCell);

                                lastPaintedCell = clampedCell;
                                EditorUtility.SetDirty(debugger);
                            }
                            break;
                    }

                    current.Use();
                    SceneView.RepaintAll();
                }

                // MouseDrag
                if (current.type == EventType.MouseDrag && current.button == 0 && GUIUtility.hotControl == controlID)
                {
                    if (isBoxDragging)
                    {
                        boxCurrentCell = clampedCell;
                        current.Use();
                        SceneView.RepaintAll();
                    }
                    else if (currentMode == EditToolMode.AddObstacle || currentMode == EditToolMode.RemoveObstacle)
                    {
                        if (isMouseInGrid && clampedCell != lastPaintedCell)
                        {
                            Undo.RecordObject(debugger, currentMode == EditToolMode.AddObstacle ? "Add Obstacle" : "Remove Obstacle");
                            if (currentMode == EditToolMode.AddObstacle)
                                debugger.AddObstacle(clampedCell);
                            else
                                debugger.RemoveObstacle(clampedCell);

                            lastPaintedCell = clampedCell;
                            EditorUtility.SetDirty(debugger);
                        }
                        current.Use();
                        SceneView.RepaintAll();
                    }
                }

                // MouseUp
                if (current.type == EventType.MouseUp && current.button == 0 && GUIUtility.hotControl == controlID)
                {
                    GUIUtility.hotControl = 0;
                    lastPaintedCell = new Vector2Int(-1, -1);

                    if (isBoxDragging)
                    {
                        isBoxDragging = false;
                        Vector2Int min = new Vector2Int(
                            Mathf.Min(boxStartCell.x, boxCurrentCell.x),
                            Mathf.Min(boxStartCell.y, boxCurrentCell.y)
                        );
                        Vector2Int max = new Vector2Int(
                            Mathf.Max(boxStartCell.x, boxCurrentCell.x),
                            Mathf.Max(boxStartCell.y, boxCurrentCell.y)
                        );

                        Undo.RecordObject(debugger, currentMode == EditToolMode.AddObstacle ? "Box Add Obstacles" : "Box Remove Obstacles");

                        if (currentMode == EditToolMode.AddObstacle)
                        {
                            debugger.AddObstaclesBox(min, max);
                        }
                        else if (currentMode == EditToolMode.RemoveObstacle)
                        {
                            debugger.RemoveObstaclesBox(min, max);
                        }

                        EditorUtility.SetDirty(debugger);
                        current.Use();
                        SceneView.RepaintAll();
                    }
                }
            }

            if (current.type == EventType.MouseMove)
            {
                SceneView.RepaintAll();
            }
        }

        private void DrawSceneViewToolbar(Rect rect)
        {
            Handles.BeginGUI();
            GUILayout.BeginArea(rect, EditorStyles.helpBox);

            GUILayout.Label("Pathfinding Grid Tool", EditorStyles.boldLabel);

            string[] modeLabels = new string[] { "View", "Start", "Goal", "Wall", "Erase" };
            currentMode = (EditToolMode)GUILayout.Toolbar((int)currentMode, modeLabels);

            if (currentMode == EditToolMode.AddObstacle || currentMode == EditToolMode.RemoveObstacle)
            {
                GUILayout.Space(2);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Shape:", GUILayout.Width(45));
                string[] shapeLabels = new string[] { "✏️ Pen", "📦 Box" };
                currentDrawShape = (DrawShapeMode)GUILayout.Toolbar((int)currentDrawShape, shapeLabels);
                GUILayout.EndHorizontal();
            }

            GUILayout.Space(3);
            if (isBoxDragging)
            {
                int minX = Mathf.Min(boxStartCell.x, boxCurrentCell.x);
                int maxX = Mathf.Max(boxStartCell.x, boxCurrentCell.x);
                int minY = Mathf.Min(boxStartCell.y, boxCurrentCell.y);
                int maxY = Mathf.Max(boxStartCell.y, boxCurrentCell.y);
                int countX = maxX - minX + 1;
                int countY = maxY - minY + 1;
                GUILayout.Label($"Drag Box: {countX}x{countY} ({countX * countY} cells)", EditorStyles.miniBoldLabel);
            }
            else if (isMouseInGrid)
            {
                GUILayout.Label($"Cell: ({lastHoveredCell.x}, {lastHoveredCell.y})", EditorStyles.miniLabel);
            }
            else
            {
                GUILayout.Label("Cursor outside grid", EditorStyles.miniLabel);
            }

            GUILayout.Space(3);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Find Path"))
            {
                Undo.RecordObject(debugger, "Run A*");
                debugger.FindPath();
                SceneView.RepaintAll();
            }

            if (GUILayout.Button("Clear Wall"))
            {
                if (EditorUtility.DisplayDialog("Clear Obstacles", "Are you sure you want to clear all obstacles?", "Yes", "No"))
                {
                    Undo.RecordObject(debugger, "Clear Obstacles");
                    debugger.ClearObstacles();
                    SceneView.RepaintAll();
                }
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(2);
            GUILayout.Label(debugger.LastSearchMessage, EditorStyles.wordWrappedMiniLabel);

            GUILayout.EndArea();
            Handles.EndGUI();
        }
    }
}
