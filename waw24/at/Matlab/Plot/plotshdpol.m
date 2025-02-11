function plotshdpol( varargin )

% plot a TL surface in dB (polar coordinates)
% usage:
% plotshdpol( filename )
%    or
% plotshdpol( filename, xs, ys, rd )
% where
%   xs, ys is the source coordinate in km
%   rd is the receiver depth in m

global units

filename = varargin{1};

if ( nargin == 2  || nargin == 3 )
   % Generate a warning.
   Message = 'Call plotshdpol with 1 or 4 inputs.';
   warning( Message );
end

if nargin > 1
   xsvec = varargin{ 2 };
   ysvec = varargin{ 3 };
   rd    = varargin{ 4 };
else
   xsvec = NaN;
   ysvec = NaN;
end

% open the file and read data

isd = 1;

for xs =  xsvec
   for ys = ysvec
      [ PlotTitle, ~, freq, ~, Pos, pressure ] = read_shd( filename, xs, ys );

      % get nrd so that tlt doesn't loose the singleton dimension when nrd = 1
      nrd = length( Pos.r.depth );
      clear tlt
      tlt( :, 1 : nrd, : ) = abs( pressure( :, 1, :, : ) );   % take first source depth
      %tlt( :, 1 : nrd, : ) = abs( pressure( 1, 1, :, 1, :, : ) );   % take first source depth

      tlt = permute( tlt, [ 2 1 3 ] );   % order so that TL( rd, x, y )
      
      % interpolate the TL field at the receiver depth
      % note: interp1 won't interpolate a vector with only 1 element
      
      if ( length( Pos.r.depth ) == 1 )
         tl = squeeze( tlt( 1, :, : ) );
      else
         tl = squeeze( interp1( Pos.r.depth, tlt, rd ) );
      end
      
      tl( isnan( tl ) ) = 1e-6;   % remove NaNs
      tl( isinf( tl ) ) = 1e-6;   % remove infinities
      tl( tl < 1e-37  ) = 1e-37;   % remove zeros
      
      tl = -20.0 * log10( tl );
      
      % if full circle, duplicate the first bearing
      
      ntheta = length( Pos.theta );
      d_theta = ( Pos.theta( end ) - Pos.theta( 1 ) ) / ( ntheta - 1 );
      
      if ( mod( Pos.theta( end ) + d_theta - Pos.theta( 1 ) + .001, 360.0 ) < .002 )
         Pos.theta( end + 1 ) = Pos.theta( end ) + d_theta;
         tl( end + 1, : ) = tl( 1, : );
      end
      tl = tl';
      
      % make plot polar
      
      [ th, r ] = meshgrid( Pos.theta, Pos.r.range );
      
      
      th        = ( 2 * pi / 360. ) * th;   % convert to radians
      [ x, y ]  = pol2cart( th, r );
      
      x = x + 1000. * xs * ones( size( x ) );
      y = y + 1000. * ys * ones( size( x ) );
      
      if ( strcmp( units, 'km' ) )
         x = x / 1000;   % convert to km
         y = y / 1000;
      end
      
      % *** plot ***

      tej = flipud( jet( 256 ) );  % 'jet' colormap reversed
      %tej = flipud( parula( 256 ) );  % 'jet' colormap reversed

      surf( x, y, tl ); shading interp
      % surfc( x, y, tl ); shading interp
      % pcolor( x, y, tl ); shading flat

      colormap( tej );
      colorbar
      % caxisrev( [ tlmin, tlmax ] )
      
      view( 2 )
      xlabel( 'Range, x (m)' )
      ylabel( 'Range, y (m)' )
      if ( strcmp( units, 'km' ) )
         xlabel( 'Range, x (km)' )
         ylabel( 'Range, y (km)' )
      end
      
      zlabel( 'Depth (m)' )
      
      % title( { deblank( PlotTitle ); [ 'Freq = ' num2str( freq ) ' Hz    Sd = ' num2str( Pos.s.depth( isd ) ) ' m' ] } )
      title( { deblank( PlotTitle ); [ 'Freq = ' num2str( freq ) ' Hz    Sd = ' num2str( Pos.s.depth( isd ) ) ' m' ...
              '   Rd = ' num2str( rd ) ' m' ...
              '   xs = ' num2str( xs ) ' km' ...
              '   ys = ' num2str( ys ) ' km' ] } )

      % axis( 'image' )
      drawnow
      hold on
   end
end