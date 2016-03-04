class FlankPreviewFlagManager extends UIUnitFlagManager;

var array<UIUnitFlag>	flankedUnitsArr;
var const int			hackingDistance;


function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int									Index;
	local UIUnitFlag							kFlag;
	local GameRulesCache_VisibilityInfo			VisibilityInfo;
	local XComGameState_Unit					SourceUnitState, TargetUnitState;
	local XComGameState_BaseObject				flagObj;
	local XComGameState_Destructible			destructibleObject;
	local XComGameState_InteractiveObject		interactiveObject;
	local UISpecialMissionHUD_Arrows			ArrowManager;
	local UISpecialMissionHUD					SpecialHUDRef;
	local T3DArrow								ObjArrow;
//	local StateObjectReference					EmptyRef;
	local TTile									ArrowTile;
	
	SpecialHUDRef = `PRES.GetSpecialMissionHUD();
	ArrowManager = UISpecialMissionHUD_Arrows(SpecialHUDRef.GetChildByName('arrowContainer'));
    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));

	//////////////////// ARROW HANDLING ////////////////////
	foreach ArrowManager.arr3Darrows(ObjArrow)
	{
		ArrowTile = `XWORLD.GetTileCoordinatesFromPosition(ObjArrow.Loc);

		switch(ObjArrow.Icon)
		{
			//Workstation hack
//			case "img:///Gotcha.UI.WorkStation_Sighted":
//			case "img:///UILibrary_Common.Objective_HackWorkstation":
//				if(SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
//				{
//					if(`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, ArrowTile, VisibilityInfo) && VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * hackingDistance))
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///Gotcha.UI.WorkStation_Sighted");
//				else
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///UILibrary_Common.Objective_HackWorkstation");
//				}
//				break;
//			//Broadcast hack (second last mission)
//			case "img:///UILibrary_Common.Objective_Broadcast":
//			case "img:///Gotcha.UI.Objective_Broadcast_Sighted":
//				if(SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
//				{
//					if(`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, ArrowTile, VisibilityInfo) && VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * hackingDistance))
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///Gotcha.UI.Objective_Broadcast_Sighted");
//				else
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///UILibrary_Common.Objective_Broadcast");
//				}
//				break;
//			//UFO hack
//			case "img:///UILibrary_Common.Objective_UFO":
//			case "img:///Gotcha.UI.Objective_UFO_Sighted":
//				if(SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
//				{
//					if(`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, ArrowTile, VisibilityInfo) && VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * hackingDistance))
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///Gotcha.UI.Objective_UFO_Sighted");
//				else
//					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///UILibrary_Common.Objective_UFO");
//				}
//				break;

			//Destroy alien transmitter
			case "img:///Gotcha.Objective_DestroyAlienFacility_spotted":
			case "img:///Gotcha.UI.DestructObj_SquadSight":
			case "img:///UILibrary_Common.Objective_DestroyAlienFacility":
				if (`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, ArrowTile, VisibilityInfo) && VisibilityInfo.bClearLOS)
				{
					if (VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * 100000))
					{
						ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///Gotcha.Objective_DestroyAlienFacility_spotted");
					}
					else 
					{
						if (SourceUnitState.HasSquadSight()) {
							ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///Gotcha.Objective_DestroyAlienFacility_spotted");
                        }
					}
				}
				else
				{
					ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, "img:///UILibrary_Common.Objective_DestroyAlienFacility");
                }
				break;
			default:
				break;
		}
	}


	//////////////////// UNIT FLAG HANDLING ////////////////////

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

//    `log("------------------");
//    `log("UNIT = " @ m_lastActiveUnit);


	foreach m_arrFlags(kFlag)
	{
	    if (kFlag.m_bIsFriendly) continue;

	    flagObj = `XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1);
//	    `log("kFlag = " @ flagObj);

	    TargetUnitState = XComGameState_Unit(flagObj);
	    destructibleObject = XComGameState_Destructible(flagObj);		//TODO: Remove this section when objective LOS is fully ported to the Arrow mechanics above
	    interactiveObject = XComGameState_InteractiveObject(flagObj);


        // Interactive Objects (e.g. door)
        if (interactiveObject != none) {
            // can see via SquadSight
            if (`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, interactiveObject.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
            {
                if (SourceUnitState.HasSquadSight())
                {
                    // display red icon
                    if(VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * 100000))
					{
						kFlag.SetAlertState(eUnitFlagAlert_None);
						SetSpottedAndFlankedState(kFlag, true, false);
					}
					else
					{
						SetSpottedAndFlankedState(kFlag, false, false);
						kFlag.SetAlertState(eUnitFlagAlert_Red);
					}
                }
                else
                {
					kFlag.SetAlertState(eUnitFlagAlert_None);
                    SetSpottedAndFlankedState(kFlag, VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * 100000), false); //What are these units??
                }
            }
            else
            {
                // remove 'spotted' icon
                SetSpottedAndFlankedState(kFlag, false, false);
				kFlag.SetAlertState(eUnitFlagAlert_None);
            }
            continue;
        }

        // Enemy Units
	    if (TargetUnitState != none) {
	        Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
	        if (Index == INDEX_NONE)
            {
                // can see via SquadSight
                if (SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
                {
                    displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, true);
                }
                else
                {
                    // remove 'spotted' icon
					kFlag.SetAlertState(eUnitFlagAlert_None);
                    SetSpottedAndFlankedState(kFlag, false, false);
                }
            }
            else
            {
                VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
				kFlag.SetAlertState(eUnitFlagAlert_None);
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo);
            }
            continue;
	    }

        // Destructible Objects (e.g. barrels)
	    if (destructibleObject != none) {
	        continue;
        }

	}
}


private function displaySpottedIcon(UIUnitFlag kFlag,
                           TTile tile,
                           XComGameState_Unit SourceUnitState,
                           XComGameState_Unit TargetUnitState,
                           GameRulesCache_VisibilityInfo VisibilityInfo,
						   optional bool Squadsight = false)
{
    // if flanked
    if (class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo))
    {
        // display yellow icon
		if(Squadsight)
		{
			SetSpottedAndFlankedState(kFlag, false, false);
			kFlag.SetAlertState(eUnitFlagAlert_Yellow);
		}
		else
		{
			kFlag.SetAlertState(eUnitFlagAlert_None); 
			SetSpottedAndFlankedState(kFlag, true, true);
		}
    }
    else
    {
        // display red icon
		if(Squadsight)
		{
			SetSpottedAndFlankedState(kFlag, false, false);
			kFlag.SetAlertState(eUnitFlagAlert_Red);
		}
		else
		{
			kFlag.SetAlertState(eUnitFlagAlert_None); 
			SetSpottedAndFlankedState(kFlag, true, false);
		}
    }
}


function SetSpottedAndFlankedState(UIUnitFlag kFlag, bool spotted, bool flanked)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool m_bFlanked;

	m_bFlanked = (flankedUnitsArr.find(kFlag) != INDEX_NONE);

	if (spotted == kFlag.m_bSpotted && flanked == m_bFlanked) return;

    // save the state
	kFlag.m_bSpotted = spotted;

	if (flanked) {
	    flankedUnitsArr.addItem(kFlag);
	} else {
	    flankedUnitsArr.removeItem(kFlag);
	}

    // display
	myValue.Type = AS_Boolean;
	myValue.b = spotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	kFlag.Invoke("SetSpottedState", myArray);
}

defaultproperties
{
	hackingDistance = 107500;
}