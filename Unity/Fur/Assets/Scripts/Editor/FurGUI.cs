using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(FurGenerator))]
public class FurGUI : Editor
{
    public override void OnInspectorGUI()
    {
        FurGenerator furGen = (FurGenerator)target;
        DrawDefaultInspector();
                
        if(GUILayout.Button("Generate & Preview Fur Mesh"))
        {
            furGen.GenerateMesh();
        }
        
        if(GUILayout.Button("Save Asset"))
        {
            furGen.path = EditorUtility.SaveFilePanel("Select folder to save fur mesh in.", "", "", "asset");

            if (furGen.path.StartsWith(Application.dataPath)) 
            {
                furGen.path =  "Assets" + furGen.path.Substring(Application.dataPath.Length);
            }

            furGen.SaveMesh();
        }
    }
}
