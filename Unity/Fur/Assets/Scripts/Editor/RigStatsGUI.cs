using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(BoneCounter))]
public class RigStatsGUI : Editor
{
    public override void OnInspectorGUI()
    {
        BoneCounter bC = (BoneCounter)target;
        DrawDefaultInspector();
                
        
        if(GUILayout.Button("Get Mesh Stats"))
        {
            bC.GetMeshStats();
        }
        if(GUILayout.Button("Get Rig Stats"))
        {
            bC.GetRigStats();
        }
    }
}
