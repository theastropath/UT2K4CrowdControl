class CrowdControlBombFlag extends xBombFlag;

var() float         GrabTime;

state Held
{
    ignores SetHolder, SendHome;

    function BeginState()
    {
        Super.BeginState();
        GrabTime = Level.TimeSeconds;
    }

    function EndState()
    {
        Super.EndState();
        GrabTime = -1;
    }
}