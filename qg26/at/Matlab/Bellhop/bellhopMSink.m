function bellhopMSink( filename )


% Beam-tracing code for ocean acoustics problems
% Copyright (C) 2009 Michael B. Porter
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% Based on the earlier Fortran version
% MBP Dec. 30, 2001
%
% For Matlab, the code had to be vectorized so all beams are traced in parallel.
% Furthermore, to keep the various vectors associated with each ray
% together in memory, it was necessary to collect them in a structure.
%
% The tracing of beams in parallel lead to huge storage requirements for the ray trajectories
% Suggests a possible rewrite to calculate TL (INFLUG module) in parallel
% with the ray trace (TRACE module).
% In the meantime, note that the run time goes through the ceiling when the
% required storage gets too large ...

clear global

tic

if ( isempty( filename ) )
    warndlg( 'No envfil has been selected', 'Warning' );
end

global ray MaxSteps Nsteps omega Bdry
global Pos
global alpha Nbeams
global U Arr MxNarr

% filenames
envfil = [ filename '.env' ];   % input environmental file
shdfil = [ filename '.shd.mat' ];   % output file name (pressure)
arrfil = [ filename '.arr.mat' ];   % output file name (arrivals)
btyfil = [ filename '.bty' ];   % input bathymetry
atifil = [ filename '.ati' ];   % input altimetry
sbpfil = [ filename '.sbp' ];   % input source beam pattern
trcfil = [ filename        ];   % input top    reflection coefficient
brcfil = [ filename        ];   % input bottom reflection coefficient

[ PlotTitle, freq, SSP, Bdry, Pos, Beam, ~, ~, fid ] = read_env( envfil, 'BELLHOP' );    % read in the environmental file
fclose( fid );                    % close out the envfil
Beam.Box.r  = 1000.0 * Beam.Box.r;
Pos.r.range = 1000.0 * Pos.r.range; % convert km to m

PlotTitle = ['BELLHOP(M) -' PlotTitle ];

TopATI = Bdry.Top.Opt(5:5);
readati( atifil, TopATI, Bdry.Top.depth, Beam.Box.r );    % read in the altimetry  file

BotBTY = Bdry.Bot.Opt(2:2);
readbty( btyfil, BotBTY, Bdry.Bot.depth, Beam.Box.r );    % read in the bathymetry file

readrc( trcfil, brcfil, Bdry.Top.Opt(2:2), Bdry.Bot.Opt(1:1) );   % READ Reflection Coefficients (top and bottom)
SrcBmPat = readpat( filename, Beam.RunType(3:3) );   % optionally read source beam pattern

MaxDepth=1000;
NumDepths=11;
n=0; % Dummy Variable Used in Loop
alpha1 = alpha;

% *** Loop Over Increasing Source Depths ***
for k = linspace(0,MaxDepth,NumDepths);
    Pos.s.depth=k; % Sets Source Depth
    n=n+1;
    alpha = alpha1;

    if ( ismember( 'A', upper( Beam.RunType(1:1) ) ) )
        MxNarr = round( max( 200000 / ( Pos.Nrd * Pos.Nrr ), 10 ) );   % allow space for at least 10 arrivals
        fprintf( '\n( Maximum # of arrivals = %i ) \n', MxNarr );
    
        Arr.A     = zeros( Pos.Nrd, Pos.Nrr, MxNarr );
        Arr.delay = zeros( Pos.Nrd, Pos.Nrr, MxNarr );
        Arr.angle = zeros( Pos.Nrd, Pos.Nrr, MxNarr );
        Arr.Narr  = zeros( Pos.Nrd, Pos.Nrr);
    else
        pressure = zeros( 1, 1, Pos.Nrd, Pos.Nrr );
    end

    MaxSteps = round( 2000000 );

    % pre-allocate
    % ray( MaxSteps ) = struct( 'c', [], 'x', [], 'Tray', [ 0 0 ], 'p', [ 0 0 ], 'q', [ 0 0 ], 'tau', [], 'Rfa', [] );
    ray( MaxSteps  ).c    = [];
    ray( MaxSteps  ).x    = [];
    ray( MaxSteps  ).Tray = [ 0 0 ];
    ray( MaxSteps  ).p    = [ 0.0 0.0 ];
    ray( MaxSteps  ).q    = [ 0.0 0.0 ];
    ray( MaxSteps  ).tau  = [];
    ray( MaxSteps  ).Rfa  = [];

    omega = 2 * pi * freq;
    Amp0  = interp1( SrcBmPat( :, 1 ), SrcBmPat( :, 2 ), alpha ); % calculate initial beam amplitude based on source beam pattern

    alpha = ( pi / 180 ) * alpha;   % convert to radians
    Dalpha = 0.0;
    if ( Nbeams ~= 1 )
        Dalpha = ( alpha( Nbeams ) - alpha( 1 ) ) / ( Nbeams - 1 );  % angular spacing between beams
    end

    Layer = 1;

    xs = [ 0.0 Pos.s.depth ];   % source coordinate
    [ c, ~, ~, ~, ~, Layer ] = ssp( xs, SSP, Layer );
    % RadMax = 10 * c / freq;  % 10 wavelength max radius
    
    % Are there enough beams?
    DalphaOpt = sqrt( c / ( 6.0 * freq * Pos.r.range( end ) ) );
    NbeamsOpt = round( 2 + ( alpha( Nbeams ) - alpha( 1 ) ) / DalphaOpt );
    
    if ( Beam.RunType(1:1) == 'C' && Nbeams < NbeamsOpt )
        fprintf( 'Warning: Nbeams should be at least = %i \n', NbeamsOpt )
    end
    
    % *** Trace rays ***
    U = zeros( length( Pos.r.depth ), length( Pos.r.range ) );
    
    if Beam.RunType(1:1) == 'R'
        figure(n)
        clf;
        plotbty(filename);
    end
    for ibeam = 1 : Nbeams
        disp( [' Tracing beam ', num2str( ibeam ) ] )
        trace( SSP, Beam.deltas, xs, alpha( ibeam ), Amp0( ibeam ), Beam.Type, Beam.Box, Beam.RunType )
        
        % ray trace run?
        if Beam.RunType(1:1) == 'R'
            figure(n)
            title( PlotTitle );
            set( gca, 'YDir', 'Reverse' )   % plot with depth-axis positive down
            hold on
            
            r = zeros( Nsteps, 1 );
            z = zeros( Nsteps, 1 );
            
            for ii = 1 : Nsteps
                r( ii ) = ray( ii ).x( 1 );
                z( ii ) = ray( ii ).x( 2 );
            end
            plot( r, z ); drawnow;
            set( gca, 'YDir', 'Reverse' )   % plot with depth-axis positive down
            
            %save RAYFIL ibeams Nsteps ray
        else
            
            if ( Beam.RunType(2:2) == 'G' )
                InfluenceGeoHat(      Pos.s.depth, alpha( ibeam ), Beam.RunType, Dalpha  )
            else
                InfluenceGeoGaussian( Pos.s.depth, alpha( ibeam ), Beam.RunType, Dalpha, Beam.deltas  )
            end
        end
    end
    if ( Beam.RunType(1:1) == 'A' )   % arrivals calculation
        
        % *** Thorpe attenuation? ***
        if ( Bdry.Top.Opt(4:4) == 'T' )
            f2 = ( freq / 1000.0 )^2;
            alpha = 40.0 * f2 / ( 4100.0 + f2 ) + 0.1 * f2 / ( 1.0 + f2 );
            alpha = alpha / 914.4;     % dB / m
            alpha = alpha / 8.6858896; % Nepers / m
        else
            alpha = 0.0;
        end
        
        % add in attenuation
        for ir = 1 : Pos.Nrr
            factor = exp( -alpha * Pos.r.range( ir ) ) / sqrt( Pos.r.range( ir ) );
            Arr.A( :, ir, : ) = factor * Arr.A( :, ir, : );
        end
        save( strcat('dp',num2str(n),arrfil), 'PlotTitle', 'Pos', 'Arr', 'MxNarr' )
    else
        pressure( 1, 1, :, : ) = scalep( Dalpha, c, Pos.r.range, U, Beam.RunType, Bdry.Top.Opt, freq );
        PlotType = 'rectilin  ';
        atten = 0;
        % problem: sd is outside the loop
        save( strcat('dp',num2str(n),shdfil), 'PlotTitle', 'PlotType', 'freq', 'atten', 'Pos', 'pressure' )
        %plotshd( shdfil )
    end
    
    
end % next source depth

toc