"""
Render Stats Toggler
"""
import maya.cmds as cmds
from collections import OrderedDict

def ToggleRenderStatsUI():
    name = 'toolWindow'
    if cmds.window(name, exists = True):
        cmds.deleteUI(name) 
    toolWindow = cmds.window(name , title = 'Render Stats Toggler', width=200)
    cmds.frameLayout(label = 'Render Stats Toggler')

    # Dictionary for label and property names of attributes.
    myDict = OrderedDict()
    myDict['Cast Shadows'] = '.castsShadows'
    myDict['Recieve Shadows'] = '.receiveShadows'
    myDict['Hold-Out'] = '.holdOut'
    myDict['Motion Blur'] = '.motionBlur'
    myDict['Primary Visibility'] = '.primaryVisibility'
    myDict['Smooth Shading'] = '.smoothShading'
    myDict['Visible in Reflections']  = '.visibleInReflections'
    myDict['Visble in Refractions' ] = '.visibleInRefractions'
    myDict['Double Sided' ] = '.doubleSided'
    myDict['Opposite'] = '.opposite'
    # print myDict # debug print list

    class Buttons():
        def __init__(self, label, attribute):
            self.label = label
            self.attribute = attribute
            # print self.label, self.attribute # gut check, printed dictionary.
            self.CreateButton(label, attribute)

        def CreateButton(self, label, attribute):
            cmds.button(label = label,  align='left', w = 200, h = 40, bgc = (0.3,0.3,0.3), command = lambda *args: self.StatToggle(attribute))

        def StatToggle(self, attribute):
            cmds.select(hi = True)
            sel = cmds.ls(selection = True, shapes = True) # create a list based on shape objects in selection.

            # print sel
            for s in sel:
                visAttr = cmds.getAttr(s + attribute)
                if visAttr == 0:
                    cmds.setAttr( s + attribute, 1 )
                    newAttrTxt = s + attribute + ' - Enabled'
                else:
                    cmds.setAttr( s + attribute, 0 )
                    newAttrTxt = s + attribute + ' - Disabled'
                print(newAttrTxt) # print attribute that's been altered
            print('\n')

    for k, v in myDict.items():
        Buttons(k, v) # insert dictionary items into class initiator.

    cmds.columnLayout()
    cmds.showWindow(toolWindow)

ToggleRenderStatsUI()