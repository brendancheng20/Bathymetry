clear all
% Runs a battery of test problems for the Acoustics Toolbox

% SPARC
sparc( 'iso' )
plotts( 'iso.rts' )

% bounce
bounce( 'refl' )
plotbrc( 'refl' )

cases = [ 'free       '; ...
          'VolAtt     '; ...
          'halfspace  '; ...
          'calib      '; ...
          'Munk       '; ...
          'MunkLeaky  '; ...
          'MunkRot    '; ...
          'sduct      '; ...
          'Dickins    '; ...
          'arctic     '; ...
          'SBCX       '; ...
          'BeamPattern'; ...
          'TabRefCoef '; ...
          'PointLine  '; ...
          'ParaBot    '; ...
          'Ellipse    '; ...
          'terrain    '; ...
          '3DAtlantic '; ...
          'wedge      '; ...
          'Gulf       '; ...
          'block      '; ...
          'PekerisRD  '; ...
          'noise      '; ...
          'step       '; ...
          'head       '; ...
          'TLslices   '; ...
              ];

for icase = 1 : size( cases, 1 )
    directory = deblank( cases( icase, : ) )
    eval( [ 'cd ' directory ] );
    runtests
    cd ..
end
