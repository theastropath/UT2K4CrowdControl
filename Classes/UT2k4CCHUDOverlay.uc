class UT2k4CCHUDOverlay extends HudOverlay;

var UT2k4CCEffects ccEffects;

simulated function Render(Canvas C)
{
    local int numLines;
    local int effectNum;
    local int baseYPos;
    local float FontDX, FontDY;
    local string effects[15];
    local int numEffects;
    local color colorBefore;

    baseYPos=5*C.ClipY/7 + C.ClipY/401;

    C.Font = HUD(Owner).GetConsoleFont(C);
    colorBefore = c.DrawColor;
    C.DrawColor.R = 255;
    C.DrawColor.G = 255;
    C.DrawColor.B = 255;
    C.DrawColor.A = 255;
    C.TextSize ("A", FontDX, FontDY);

    if (ccEffects==None){
        foreach AllActors(class'UT2k4CCEffects',ccEffects){
            log("Found CCEffects "$ccEffects);
            break;
        }
    }
    if (ccEffects!=None){
        ccEffects.GetEffectList(effects,numEffects);
        if (numEffects>0){
            C.SetPos(5, baseYPos+(numLines*FontDY));
            C.DrawText("Crowd Control Effects:");
            numLines++;
        
            for(effectNum=0;effectNum<ArrayCount(effects) && effects[effectNum]!="";effectNum++){
                C.SetPos(5, baseYPos+(numLines*FontDY));
                C.DrawText(effects[effectNum]);
                numLines++;
            }
        }
    } else {
        log("ccEffects is still none!");
    }
    c.DrawColor=colorBefore;
}