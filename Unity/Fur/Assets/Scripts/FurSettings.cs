using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "FurSettings", menuName = "Fur/CreateFurSettings", order = 1)]
public class FurSettings : ScriptableObject
{
    public bool UseMask;
    public Material furMaterial;
    [Range(0,16)]
    public int numberOfShells;
    public float furLength;
    public string path;
}
