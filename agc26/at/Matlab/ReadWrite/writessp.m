function writessp( sspfil, rkm, c )
% Write an SSP matrix
% sspfil is the name of the SSP file
% rkm is the range in km of each profile in c
% c is the matrix of sound speed profiles

Npts = length( rkm );

fid = fopen( sspfil, 'w' );

fprintf( fid, '%i \r\n', Npts );
fprintf( fid, '%6.3f  ', rkm );
fprintf( fid, ' \r\n' );

for ii = 1 : size( c, 1 )
   fprintf( fid, '%6.1f ', c( ii, : ) );
   fprintf( fid, ' \r\n' );
end

fclose( fid );

