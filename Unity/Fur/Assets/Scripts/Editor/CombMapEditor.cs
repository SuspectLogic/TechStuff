using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.UI;
using UnityEngine.EventSystems;


namespace FurTools.UI
{
    
    public class CombMapEditor : EditorWindow
    {
        GraphicRaycaster m_Raycaster;
        PointerEventData m_PointerEventData;
        GameObject go;

        int tab = 0;
        string[] toolbarItems = {"Fur Generator", "Comb Map Editor"};

        [MenuItem("Tools/FurTools/CombMapEditor")]
        static void Init()
        {
            CombMapEditor editor = (CombMapEditor)EditorWindow.GetWindow(typeof(CombMapEditor));
            editor.Show();
        }

        void OnGUI()
        {
            GUILayout.BeginHorizontal();
            tab = GUILayout.Toolbar(tab, toolbarItems);
            GUILayout.EndHorizontal();


            if(Input.GetMouseButtonDown(0))
            {
                Debug.Log("ButtonClicked");

            }
            // m_Raycaster = GetComponent<GraphicRaycaster>();
            // switch(tab)
            // {
                
            // }
            
        }
        
    }

}

