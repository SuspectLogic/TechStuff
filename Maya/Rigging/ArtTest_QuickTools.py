'''
Some simple tools I made for speeding up the rigging art test.
'''

import maya.cmds as cmds

def ShowAxis(*args):
    global value

    childJoints = GetJointSelection()
    
    for c in childJoints:
        cmds.setAttr(c + '.displayLocalAxis', value)

    if value == False:
        value = True
    elif value == True:
        value = False

def CountJoints(*args):
    childJoints = GetJointSelection()
    jointCount = len(childJoints)
    print(jointCount)
    cmds.confirmDialog(title = 'Joint Count', message = 'Total Joints: ' + str(jointCount), db = 'Okay')

def SetJointSize(*args):
    childJoints = GetJointSelection()
    js = cmds.floatField(jointSize, q = True, v = True)
    for c in childJoints:
        print(c.lower())
        if "root" in c.lower():
            cmds.setAttr(c + '.radius', js * 2)
        else:
            cmds.setAttr(c + '.radius', js)

def GetJointSelection():
    sl = cmds.ls(sl = True)
    cj = cmds.listRelatives(sl, allDescendents = True, type = 'joint')
    return cj

# This will set the color that's given.
def SetRGBColor(ctrl, color):
    rgb = ("R","G","B")    
    cmds.setAttr(ctrl + ".overrideEnabled",1)
    cmds.setAttr(ctrl + ".overrideRGBColors",1)    
    for channel, color in zip(rgb, color):        
        cmds.setAttr(ctrl + ".overrideColor%s" %channel, color)

def SetColorForShapes():
    
    yellow = (1.0, 1.0, 0.0)
    blue = (0.55,0.55,1.0)
    red = (1.0,0.3,0.3 )

    sl = cmds.ls(sl = True)
    shapes = cmds.listRelatives(sl, ad = True, type = 'shape')

    for s in shapes:
        parent = sl[0] + "|"
        currentShape = parent + s
        
        SetRGBColor(currentShape, blue) 

class QuickToolsUI():
    def __init__(self):
        global value
        global jointSize

        name = 'Art Test Joint Tools'
        if cmds.window(name, exists = True):
            cmds.deleteUI(name)

        toolWindow = cmds.window(name, title = name, widthHeight = (200, 200))

        value = True # Tool automatically assumes value is True when launched.
        
        cmds.columnLayout(adjustableColumn=True)

        cmds.button(label = 'Toggle Local Rotation Axis', c = ShowAxis)
        cmds.button(label = 'Count Joints', c = CountJoints)

        cmds.columnLayout()
        jointSize = cmds.floatField(min = 0, max = 10)
        cmds.button(label = 'Set Joint Size', c = SetJointSize)
        cmds.button(label = 'Set color for childs shapes', c = SetColorForShapes)
        cmds.setParent('..')

        cmds.showWindow(toolWindow)

QuickToolsUI()
