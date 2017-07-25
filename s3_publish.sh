rm -rf cloudfront.json
hugo
s3cmd sync -MP public/* s3://joshrendek.com/
./cloudfront.rb
aws cloudfront create-invalidation --distribution-id E1BWED0Y2Z4J77 --invalidation-batch file://cloudfront.json
aws cloudfront list-invalidations --distribution-id E1BWED0Y2Z4J77 | grep InProgress
