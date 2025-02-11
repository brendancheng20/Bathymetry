function trace( SSP, deltas, xs, alpha, Amp0, BeamType, Box, RunType )

global ray MaxSteps Nsteps Bdry Layer
global xTop tTop nTop tTopNode nTopNode RLenTop kappaTop NatiPts atiType
global xBot tBot nBot tBotNode nBotNode RLenBot kappaBot NbtyPts btyType

% Traces the beam corresponding to a particular take-off angle

% MaxSteps = 100000;
%
% pre-allocate the ray structure
% (doesn't seem to save any time though)
% ray( MaxSteps ).c    = [];
% ray( MaxSteps ).x    = [];
% ray( MaxSteps ).Tray = [ 1 0 ];
% ray( MaxSteps ).p    = [ 1 0 ];
% ray( MaxSteps ).q    = [ 0 1 ];
% ray( MaxSteps ).tau  = 0;
% ray( MaxSteps ).Rfa  = Amp0;

% *** Initial conditions ***
Layer = 1;
[ c, ~, ~, ~, ~, Layer ] = ssp( xs, SSP, Layer );

ray( 1 ).c    = c;
ray( 1 ).x    = xs;
ray( 1 ).Tray = [ cos( alpha ) sin( alpha ) ] / c;
ray( 1 ).p    = [ 1.0 0.0 ];
ray( 1 ).q    = [ 0.0 1.0 ];
ray( 1 ).tau  = 0;
ray( 1 ).Rfa  = Amp0;

% second component of qv is not used in geometric beam tracing
% set I.C. to 0 in hopes of saving run time
if (RunType(2:2) == 'G' )
    ray( 1 ).qv = zeros( 1, 2 ) ;
end

% *** identify the top segment above the source

IsegTopT = find( xTop( 1, 1:NatiPts) <= xs( 1 ) );

if ( IsegTopT( end ) > 0 && IsegTopT( end ) < NatiPts )
    IsegTop  = IsegTopT( end );	% IsegTop MUST LIE IN [ 1, NatiPts-1 ]
    rTopSeg  = [ xTop( 1, IsegTop ) xTop( 1, IsegTop + 1 ) ];
else
    disp( 'Fatal Error: Top altimetry undefined above the source' )
end

% *** identify the bottom segment below the source

IsegBotT = find( xBot( 1, 1:NbtyPts) <= xs( 1 ) );

if ( IsegBotT( end ) > 0 && IsegBotT( end ) < NbtyPts )
    IsegBot  = IsegBotT( end );	% IsegBot MUST LIE IN [ 1, NbtyPts-1 ]
    rBotSeg  = [ xBot( 1, IsegBot ) xBot( 1, IsegBot + 1 ) ];
else
    disp( 'Fatal Error: Bottom bathymetry undefined below the source' )
end

% *** Overhang? ***
trigger=0;
for n=2:length(xBot)
    test = find(xBot(1,n)<xBot(1,n-1));
    if test==1
        trigger=1;
        cutoff = n;
        break;
    end
end

%% Normal Trace
% if trigger==0;
    
% *** Trace the beam ***

for I = 1 : MaxSteps
    I0 = I;
    I1 = I + 1;
    
    %make sure shape is correct
    ray( I1 ).c    = c;
    ray( I1 ).q    = [ 0.0 1.0 ];  % need to ensure q( 1 ) exists in INFLUG for caustic count
    ray( I1 ).tau  = 0;
    ray( I1 ).Rfa  = 1;
    
    [ ray( I1 ).x, ray( I1 ).Tray, ray( I1 ).p, ray( I1 ).q, ray( I1 ).tau, ray( I1 ).Rfa, ray( I1 ).c ] = ...
        step( SSP, ray( I0 ).x, ray( I0 ).Tray, ray( I0 ).p, ray( I0 ).q, ray( I0 ).tau, ray( I0 ).Rfa, ...
        xTop( :, IsegTop )', nTop( :, IsegTop )', ...
        xBot( :, IsegBot )', nBot( :, IsegBot )',  rTopSeg, rBotSeg, deltas );
    
    % *** New altimetry segment? ***
    
    if ( ray( I1 ).x( 1 ) < rTopSeg( 1 ) || ...
         ray( I1 ).x( 1 ) > rTopSeg( 2 ) )
        IsegTopT = find( xTop( 1, : ) < ray( I1 ).x( 1 ) );
        if ( isempty( IsegTopT ) == 1 )   % no altimetry point behind us
            IsegTop = 1;
        else
            IsegTop = min( IsegTopT( end ), NatiPts - 1 ); % limit segment to last one in altimetry data
        end
        rTopSeg  = [ xTop( 1, IsegTop ) xTop( 1, IsegTop + 1 ) ];
    end
    
    % *** New bathymetry segment? ***
    
    if ( ray( I1 ).x( 1 ) < rBotSeg( 1 ) || ...
         ray( I1 ).x( 1 ) > rBotSeg( 2 ) )
        IsegBotT = find( xBot( 1, : ) < ray( I1 ).x( 1 ) );
        if ( isempty( IsegBotT ) == 1 )   % no bathymetry point behind us
            IsegBot = 1;
        else
            IsegBot = min( IsegBotT( end ), NbtyPts - 1 ); % limit segment to last one in bathymetry data
        end
        rBotSeg  = [ xBot( 1, IsegBot ) xBot( 1, IsegBot + 1 ) ];
    end
    
    % *** Reflections? ***
    % Tests that ray at step i is inside, and ray at step i+1 is outside
    % to detect only a crossing from inside to outside
    
    DBegTop    = ray( I  ).x - xTop( :, IsegTop )';  % vector pointing from top    to ray
    DBegBot    = ray( I  ).x - xBot( :, IsegBot )';  % vector pointing from bottom to ray
    DistBegTop = DBegTop * nTop( :, IsegTop );
    DistBegBot = DBegBot * nBot( :, IsegBot );
    
    DEndTop    = ray( I1 ).x - xTop( :, IsegTop )';  % vector pointing from top    to ray
    DEndBot    = ray( I1 ).x - xBot( :, IsegBot )';  % vector pointing from bottom to ray
    DistEndTop = DEndTop * nTop( :, IsegTop );
    DistEndBot = DEndBot * nBot( :, IsegBot );
    
    if ( DistBegTop < 0.0 && DistEndTop >= 0.0 )
        % interpolate top normal and tangent by proportional distance along the segment
        
        if ( atiType == 'C' )   % curvilinear
            sss     = dot( DEndTop', tTop( :, IsegTop ) );
            alpha   = sss / RLenTop( IsegTop );
            nTopInt = ( 1 - alpha ) * nTopNode( :, IsegTop ) + alpha * nTopNode( :, 1 + IsegTop );
            tTopInt = ( 1 - alpha ) * tTopNode( :, IsegTop ) + alpha * tTopNode( :, 1 + IsegTop );
        else                    % linear
            nTopInt = nTop( :, IsegTop );
            tTopInt = tTop( :, IsegTop );
        end
        
        BC(1:1) = Bdry.Top.Opt(2:2);
        reflect( I1, BeamType, BC, Bdry.Top.cp, Bdry.Top.rho, 'TOP', ...
            tTopInt', nTopInt', kappaTop( IsegTop ), SSP )
    end
    
    if ( DistBegBot < 0.0 && DistEndBot >= 0.0 )
        % interpolate bottom normal and tangent by proportional distance along the segment
        
        if ( btyType == 'C' )   % curvilinear
            sss     = dot( DEndBot', tBot( :, IsegBot ) );
            alpha   = sss / RLenBot( IsegBot );
            nBotInt = ( 1 - alpha ) * nBotNode( :, IsegBot ) + alpha * nBotNode( :, 1 + IsegBot );
            tBotInt = ( 1 - alpha ) * tBotNode( :, IsegBot ) + alpha * tBotNode( :, 1 + IsegBot );
        else                    % linear
            nBotInt = nBot( :, IsegBot );
            tBotInt = tBot( :, IsegBot );
        end
        
        BC = Bdry.Bot.Opt(1:1);
        reflect( I1, BeamType, BC, Bdry.Bot.cp, Bdry.Bot.rho, 'BOT', ...
            tBotInt', nBotInt', kappaBot( IsegBot ), SSP )
    end
    
    % *** Has the ray left the box, lost its energy, or escaped the boundaries? ***
    
    if ( ( abs( ray( I1 ).x( 1 ) ) > Box.r ) || ...
         (      ray( I1 ).x( 2 )   > Box.z ) || ...
         ( abs( ray( I1 ).Rfa )    < 0.005 ) || ...
         ( DistBegTop > 0.0 && DistEndTop > 0.0 ) || ...
         ( DistBegBot > 0.0 && DistEndBot > 0.0 ) )
        
        Nsteps = I1;
        return
    end
    
end   % Next step

Nsteps = MaxSteps;
fprintf( 'bellhop:trace: Terminating ray trace at limit of MaxSteps = %i \n\n', MaxSteps )

% %% Trace for Overhang Bathymetry
% else
% 
%     % Exclude Overhang from Bottom bathymetry
%     newxBot1=xBot(:,1:cutoff);
%     res=0;
%     for k=cutoff+1:length(xBot);
%         if (xBot(1,k)>xBot(1,cutoff))
%             res=k;
%             break
%         end
%     end
% 
%     ohang = xBot(:,cutoff+1:res-1);
%     newxBot2=xBot(:,res:length(xBot));
%     newxBot=[newxBot1 newxBot2];
%     newNbtyPts=length(newxBot);
%     
%     % Split Overhang Top and Bottom
%     split = 0;
%     for k=2:length(ohang);
%         if (ohang(1,k)>ohang(1,k-1))
%             split=k;
%             break;
%         end
%     end
%     ohbot=ohang(:,1:split-1);
%     ohtop=ohang(:,split:end);
%     
%     IsegBotT = find( newxBot( 1, 1:newNbtyPts) <= xs( 1 ) );
% 
%     if ( IsegBotT( end ) > 0 && IsegBotT( end ) < newNbtyPts )
%         IsegBot  = IsegBotT( end );	% IsegBot MUST LIE IN [ 1, NbtyPts-1 ]
%         rBotSeg  = [ newxBot( 1, IsegBot ) newxBot( 1, IsegBot + 1 ) ];
%     else
%         disp( 'Fatal Error: Bottom bathymetry undefined below the source' )
%     end
% 
%     for I = 1 : MaxSteps
%     I0 = I;
%     I1 = I + 1;
%       
%     %make sure shape is correct
%     ray( I1 ).c    = c;
%     ray( I1 ).q    = [ 0.0 1.0 ];  % need to ensure q( 1 ) exists in INFLUG for caustic count
%     ray( I1 ).tau  = 0;
%     ray( I1 ).Rfa  = 1;
%     
%     [ ray( I1 ).x, ray( I1 ).Tray, ray( I1 ).p, ray( I1 ).q, ray( I1 ).tau, ray( I1 ).Rfa, ray( I1 ).c ] = ...
%         step( SSP, ray( I0 ).x, ray( I0 ).Tray, ray( I0 ).p, ray( I0 ).q, ray( I0 ).tau, ray( I0 ).Rfa, ...
%         xTop( :, IsegTop )', nTop( :, IsegTop )', ...
%         newxBot( :, IsegBot )', nBot( :, IsegBot )',  rTopSeg, rBotSeg, deltas );
%     
%     % *** New altimetry segment? ***
%     
%     if ( ray( I1 ).x( 1 ) < rTopSeg( 1 ) || ...
%          ray( I1 ).x( 1 ) > rTopSeg( 2 ) )
%         IsegTopT = find( xTop( 1, : ) < ray( I1 ).x( 1 ) );
%         if ( isempty( IsegTopT ) == 1 )   % no altimetry point behind us
%             IsegTop = 1;
%         else
%             IsegTop = min( IsegTopT( end ), NatiPts - 1 ); % limit segment to last one in altimetry data
%         end
%         rTopSeg  = [ xTop( 1, IsegTop ) xTop( 1, IsegTop + 1 ) ];
%     end
%     
%     % *** New bathymetry segment? ***
%     
%     if ( ray( I1 ).x( 1 ) < rBotSeg( 1 ) || ...
%          ray( I1 ).x( 1 ) > rBotSeg( 2 ) )
%         IsegBotT = find( newxBot( 1, : ) < ray( I1 ).x( 1 ) );
%         if ( isempty( IsegBotT ) == 1 )   % no bathymetry point behind us
%             IsegBot = 1;
%         else
%             IsegBot = min( IsegBotT( end ), NbtyPts - 1 ); % limit segment to last one in bathymetry data
%         end
%         rBotSeg  = [ newxBot( 1, IsegBot ) newxBot( 1, IsegBot + 1 ) ];
%     end
%     
%     % *** Reflections? ***
%     % Tests that ray at step i is inside, and ray at step i+1 is outside
%     % to detect only a crossing from inside to outside
%     
%     DBegTop    = ray( I  ).x - xTop( :, IsegTop )';  % vector pointing from top    to ray
%     DBegBot    = ray( I  ).x - newxBot( :, IsegBot )';  % vector pointing from bottom to ray
%     DistBegTop = DBegTop * nTop( :, IsegTop );
%     DistBegBot = DBegBot * nBot( :, IsegBot );
%     
%     DEndTop    = ray( I1 ).x - xTop( :, IsegTop )';  % vector pointing from top    to ray
%     DEndBot    = ray( I1 ).x - newxBot( :, IsegBot )';  % vector pointing from bottom to ray
%     DistEndTop = DEndTop * nTop( :, IsegTop );
%     DistEndBot = DEndBot * nBot( :, IsegBot );
%     
%     
%     if ( DistBegTop < 0.0 && DistEndTop >= 0.0 )
%         % interpolate top normal and tangent by proportional distance along the segment
%         
%         if ( atiType == 'C' )   % curvilinear
%             sss     = dot( DEndTop', tTop( :, IsegTop ) );
%             alpha   = sss / RLenTop( IsegTop );
%             nTopInt = ( 1 - alpha ) * nTopNode( :, IsegTop ) + alpha * nTopNode( :, 1 + IsegTop );
%             tTopInt = ( 1 - alpha ) * tTopNode( :, IsegTop ) + alpha * tTopNode( :, 1 + IsegTop );
%         else                    % linear
%             nTopInt = nTop( :, IsegTop );
%             tTopInt = tTop( :, IsegTop );
%         end
%         
%         BC(1:1) = Bdry.Top.Opt(2:2);
%         reflect( I1, BeamType, BC, Bdry.Top.cp, Bdry.Top.rho, 'TOP', ...
%             tTopInt', nTopInt', kappaTop( IsegTop ), SSP )
%     end
%     
%     if ( DistBegBot < 0.0 && DistEndBot >= 0.0 )
%         % interpolate bottom normal and tangent by proportional distance along the segment
%         
%         if ( btyType == 'C' )   % curvilinear
%             sss     = dot( DEndBot', tBot( :, IsegBot ) );
%             alpha   = sss / RLenBot( IsegBot );
%             nBotInt = ( 1 - alpha ) * nBotNode( :, IsegBot ) + alpha * nBotNode( :, 1 + IsegBot );
%             tBotInt = ( 1 - alpha ) * tBotNode( :, IsegBot ) + alpha * tBotNode( :, 1 + IsegBot );
%         else                    % linear
%             nBotInt = nBot( :, IsegBot );
%             tBotInt = tBot( :, IsegBot );
%         end
%         
%         BC = Bdry.Bot.Opt(1:1);
%         reflect( I1, BeamType, BC, Bdry.Bot.cp, Bdry.Bot.rho, 'BOT', ...
%             tBotInt', nBotInt', kappaBot( IsegBot ), SSP )
%     end
%     
%     % Finding tangential and normal lines for overhang geometry
%     
%     tohtop( 1, : ) = ohtop( 1, 2:end ) - ohtop( 1, 1:end - 1 );
%     tohtop( 2, : ) = ohtop( 2, 2:end ) - ohtop( 2, 1:end - 1 );
%     
%     RLenohtop = sqrt( tohtop( 1, : ).^ 2 + tohtop( 2, : ).^ 2 );
%     
%     tohtop( 1, : ) = tohtop( 1, : ) ./ RLenohtop;
%     tohtop( 2, : ) = tohtop( 2, : ) ./ RLenohtop;
%     
%     nohtop( 1, : ) =  tohtop( 2, : );
%     nohtop( 2, : ) = -tohtop( 1, : );
%     
%     tohbot( 1, : ) = ohbot( 1, 2:end ) - ohbot( 1, 1:end - 1 );
%     tohbot( 2, : ) = ohbot( 2, 2:end ) - ohbot( 2, 1:end - 1 );
%     
%     RLenohbot = sqrt( tohbot( 1, : ).^ 2 + tohbot( 2, : ).^ 2 );
%     
%     tohbot( 1, : ) = tohbot( 1, : ) ./ RLenohbot;
%     tohbot( 2, : ) = tohbot( 2, : ) ./ RLenohbot;
%     
%     nohbot( 1, : ) =  tohbot( 2, : );
%     nohbot( 2, : ) = -tohbot( 1, : );
%     
%     % Determine if the ray passes over one of the overhang boundaries
%     if (ray(I).x(1)>ohbot(1,end) && ray(I).x(1)<ohbot(1,1)) || ...
%             (ray(I1).x(1)>ohbot(1,end) && ray(I1).x(1)<ohbot(1,1))
%     rbot = find(min(ohbot(:,1)-ray(I).x(1)));
%     rtop = find(min(ohtop(:,1)-ray(I).x(1)));
%     rbot1 = find(min(ohbot(:,1)-ray(I1).x(1)));
%     rtop1 = find(min(ohtop(:,1)-ray(I1).x(1)));
% 
%     DBegOHTop    = ray( I  ).x - ohtop( :, rtop )';  % vector pointing from top    to ray
%     DBegOHBot    = ray( I  ).x - ohbot( :, rbot)';  % vector pointing from bottom to ray
%     DistBegOHTop = DBegTop * nohtop( :, rtop );
%     DistBegOHBot = DBegBot * nohbot( :, rbot );
%     
%     DEndOHTop    = ray( I1 ).x - ohtop( :, rtop1 )';  % vector pointing from top    to ray
%     DEndOHBot    = ray( I1 ).x - ohbot( :, rbot1 )';  % vector pointing from bottom to ray
%     DistEndOHTop = DEndTop * nohtop( :, rtop1 );
%     DistEndOHBot = DEndBot * nohbot( :, rbot1 );
%     
%     % Reflect Off the Overhang
%     
%     if ( DistBegOHBot < 0.0 && DistEndOHBot >= 0.0)
%             nOHBotInt = nohbot( :, rbot );
%             tOHBotInt = tohbot( :, rbot );
%         BC = Bdry.Bot.Opt(1:1);
%         reflect( I1, BeamType, BC, Bdry.Bot.cp, Bdry.Bot.rho, 'BOT', ...
%             tOHBotInt', nOHBotInt', kappaBot( rbot), SSP )
%     end
%     
%     if ( DistBegOHTop < 0.0 && DistEndOHTop >= 0.0 )
%             nOHTopInt = nohtop( :, rtop );
%             tOHTopInt = tohtop( :, rtop );
%         BC = Bdry.Bot.Opt(1:1);
%         reflect( I1, BeamType, BC, Bdry.Bot.cp, Bdry.Bot.rho, 'BOT', ...
%             tOHTopInt', nOHTopInt', kappaBot( rbot ), SSP )
%     end
%     end
%     
%     % *** Has the ray left the box, lost its energy, or escaped the boundaries? ***
%     
%     if ( ( abs( ray( I1 ).x( 1 ) ) > Box.r ) || ...
%          (      ray( I1 ).x( 2 )   > Box.z ) || ...
%          ( abs( ray( I1 ).Rfa )    < 0.005 ) || ...
%          ( DistBegTop > 0.0 && DistEndTop > 0.0 ) || ...
%          ( DistBegBot > 0.0 && DistEndBot > 0.0 ) )
%         
%         Nsteps = I1;
%         return
%     end
%     
%     end   % Next step
% 
% Nsteps = MaxSteps;
% fprintf( 'bellhop:trace: Terminating ray trace at limit of MaxSteps = %i \n\n', MaxSteps )

end