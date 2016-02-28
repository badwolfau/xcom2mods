class HackableObjectIcon extends UIIcon;

const ICON_SIZE = 32;

simulated function HackableObjectIcon Init(X2VisualizerInterface Visualizer)
{
    local UIBGBox FlankMarker;
    local UIImage img;
    local HackableObjectIcon hackableObjectIcon;

	InitIcon(,,false,true,ICON_SIZE,Visualizer.GetMyHUDIconColor());

	SetPosition(20, -35);

    img = Spawn(class'UIImage', self).InitImage(,Visualizer.GetMyHUDIcon());
    img.SetPosition(-1, -1);
    img.SetSize(ICON_SIZE + 6, ICON_SIZE + 6);

	return self;
}

simulated function SetIconPosition(int flagX, int flagY)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	// Only update if a new value has been passed in.
//	if ((m_positionV2.X != flagX) || (m_positionV2.Y != flagY) )
//	{
//		m_positionV2.X = flagX;
//		m_positionV2.Y = flagY;

		myValue.Type = AS_Number;

		myValue.n = flagX;
		myArray.AddItem( myValue );
		myValue.n = flagY;
		myArray.AddItem( myValue );
		myValue.n = 1;
		myArray.AddItem( myValue );

		Invoke("SetPosition", myArray);
//	}
}
