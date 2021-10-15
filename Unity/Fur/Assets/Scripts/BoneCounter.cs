using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations;

public class BoneCounter : MonoBehaviour
{
    // Start is called before the first frame update
    public bool PrintWeightsInfo;
    public void GetStats()
    {
        var renderer = gameObject.GetComponent<SkinnedMeshRenderer>();
        var mesh = renderer.sharedMesh;
        var boneCount = renderer.bones.Length;
        if(boneCount == 0)
        {
            Avatar av = gameObject.GetComponentInParent<Animator>().avatar;
            // Debug.Log(av.name);
            SkeletonBone[] bones = av.humanDescription.skeleton;
            
            // for(int i = 0; i< mesh.bindposes.Length; i++)
            // {
            //     Debug.Log(bones[i].name);
            // }
        }
        else
        {
            Debug.Log("Bone count: " + renderer.bones.Length);
        }        
              
    }

    public void GetMeshStats()
    {
        Mesh mesh = new Mesh();
        if(TryGetComponent<SkinnedMeshRenderer>(out SkinnedMeshRenderer sr))
        {
            mesh = sr.sharedMesh;
        }

        else if(TryGetComponent<MeshFilter>(out MeshFilter m))
        {
            mesh = m.sharedMesh;
        }

        Debug.Log("Vertices: " + mesh.vertices.Length);
        Debug.Log("Normals: "+ mesh.normals.Length);
        Debug.Log("Tris: "+ mesh.triangles.Length);
        Debug.Log("BoneWeights: "+ mesh.boneWeights.Length);
    }

    public void GetRigStats()
    {
        Mesh mesh = new Mesh();
        if(TryGetComponent<SkinnedMeshRenderer>(out SkinnedMeshRenderer sr))
        {
            mesh = sr.sharedMesh;
        }

        else if(TryGetComponent<MeshFilter>(out MeshFilter m))
        {
            mesh = m.sharedMesh;
        }

        if(PrintWeightsInfo)
        {
            for(int i =0; i< mesh.boneWeights.Length; i++)
            {
                var index0 = mesh.boneWeights[i].boneIndex0;
                var index1 = mesh.boneWeights[i].boneIndex1;
                var index2 = mesh.boneWeights[i].boneIndex2;
                var index3 = mesh.boneWeights[i].boneIndex3;

                Debug.Log( "Bone: " + index0 + ", " + "Bone: " + index1 +  ", "  + "Bone: " + index2 + ", " + "Bone: " + index3);
            }
        }  



    }
}
