'''
This tool does the following steps:
    Extract:
        - User selects faces. selection gets stored in a list.
        - Tool checks name validity.
        - Duplicates source mesh.
        - Copies skin weights from src to dup mesh.
        - Selects faces from the provided face list.
        - inverts the selection for the dup mesh.
        - deletes the selection for the source and duplicated mesh.
        - Cleans modeling history.
    Combine:
        - User selects any number of meshes from outliner or scene.
        - Tool checks name validity.
        - Tool uses "polyUniteSkinned" command for combining list.
        - Deletes remaining transforms and renames the resulting mesh.
'''

import maya.cmds as cmds
import maya.mel as mel

def CombineMesh(*args):
    selectedObjects = cmds.ls(sl=True, fl = True)
    queriedName = cmds.textField(txtFieldName, q = True, tx = True)

    CheckName(queriedName) 

    combine = cmds.polyUniteSkinned(selectedObjects) # -- for future reference: item 0 is resulting name, 1 is resulting skinCluster. 

    # Delete leftover nodes.
    for s in selectedObjects:
        if cmds.objExists(s):
            cmds.delete(s)
            print( 'Leftover node ' + str(s) + ' was removed.')
        
    if queriedName == '':
        queriedName = selectedObjects[0]

    cmds.rename(combine[0], queriedName)
    print('Skinned mesh was successfully combined!')

def ExtractMesh(*args):
    selectedFaces = cmds.ls(sl=True, fl = True) # Maya returns a range as dict rather than individual items if fl isn't true.
    queriedName = cmds.textField(txtFieldName, q = True, tx = True)

    CheckName(queriedName)

    if len(selectedFaces) > 0:
        srcObject = selectedFaces[0].split('.')[0]
        faceNumbers = GetFaceNumbers(selectedFaces)
        dsObj = cmds.duplicate(srcObject, name = queriedName)[0]
        CopySkinWeights(srcObject, dsObj)
        Cleanup(srcObject, dsObj, faceNumbers)
    else:
        print('No polygonal faces are selected')

def GetFaceNumbers(sF):
    faceNumbers = []
    for f in sF:
        faceNumbers.append(f.split('.f')[-1]) # extract number
    return faceNumbers

def CopySkinWeights(srcObject, dsObj):
    history = cmds.listHistory(srcObject, pdo=True)
    srcCluster = cmds.ls(history, type = 'skinCluster') or [None]
    jointList = cmds.skinCluster(srcObject , q=True , inf=True)
    newCluster = cmds.skinCluster(dsObj, jointList, n = 'skinCluster', tsb = True, dr = 4.0, mi = 4)
    cmds.copySkinWeights(ss = srcCluster[0], ds = newCluster[0], sa = 'closestPoint', ia = 'closestJoint', nm = True)
    cmds.skinCluster(newCluster, e = True, rui = True)

def Cleanup(srcObject, dsObj, fN):
    cmds.select(cl = True)
    SelectFaces(dsObj, fN)
    mel.eval('invertSelection')
    SelectFaces(srcObject, fN)
    cmds.delete()
    cmds.bakePartialHistory(srcObject, dsObj, ppt = True)

def SelectFaces(inputString, fN):
    for f in fN:
        cmds.select(inputString + '.f' + f, add = True)

# Check the validity of the provided name.
def CheckName(name):
    if cmds.objExists(name):
        raise TypeError("Warning: this name is already in use.")
    if name == '':
        print('No name given, defaulting to using the name from extracted object')

class SkinnedMeshTools():
    def __init__(self):
        global txtFieldName

        name = 'Mesh Tools'
        if cmds.window(name, exists = True):
            cmds.deleteUI(name)
        
        toolWindow = cmds.window(name, title = 'Skinned Mesh Tools', width=300, height = 200)
        cmds.columnLayout()
        cmds.frameLayout(label = 'Name for new mesh', bgc = [0.2,0.2,0.2])
        cmds.columnLayout()
        txtFieldName = cmds.textField(w= 600)
        cmds.textField(ed = False, w=600, io = True)
        grid = cmds.gridLayout(numberOfColumns = 2,nr = 2, cellWidthHeight = (300, 40))
        cmds.text(l = 'Extracts selected faces' ,al = 'center', p = grid, en = False)
        cmds.text(l = 'Combines selected meshhes' ,al = 'center', p = grid, en = False)
        cmds.button( label='Extract', p = grid,align='left',width = 300, bgc = (0.3,0.3,0.3), command = ExtractMesh)
        cmds.button( label='Combine', p = grid, align='right',width = 300, bgc = (0.3,0.3,0.3), command = CombineMesh)
        cmds.setParent( '..' )

        cmds.showWindow(toolWindow)

SkinnedMeshTools()