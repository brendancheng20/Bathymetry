clear all
% Runs a battery of test problems for BELLHOP3D

cases = [ 'halfspace      '; ...
          'ParaBot        '; ...
          'Munk           '; ...
          'MunkRot        '; ...
          'KoreanSeas     '; ...
          'Taiwan         '; ...
          'PerfectWedge   '; ...
          'PenetrableWedge'; ...
          'TruncatedWedge '; ...
          'Seamount       '; ...
              ];

for icase = 1 : size( cases, 1 )
    directory = deblank( cases( icase, : ) )
    eval( [ 'cd ' directory ] );
    runtests
    cd ..
end
