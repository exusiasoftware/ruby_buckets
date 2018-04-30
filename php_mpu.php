use Aws\S3\S3Client;

$bucket = '*** Your Bucket Name ***';
$keyname = '*** Your Object Key ***';
$filename = '*** Path to and Name of the File to Upload ***';					
					
// 1. Instantiate the client.
$s3 = S3Client::factory();

// 2. Create a new multipart upload and get the upload ID.
$response = $s3->createMultipartUpload(array(
    'Bucket' => $bucket,
    'Key'    => $keyname
));
$uploadId = $response['UploadId'];

// 3. Upload the file in parts.
$file = fopen($filename, 'r');
$parts = array();
$partNumber = 1;
while (!feof($file)) {
    $result = $s3->uploadPart(array(
        'Bucket'     => $bucket,
        'Key'        => $key,
        'UploadId'   => $uploadId,
        'PartNumber' => $partNumber,
        'Body'       => fread($file, 5 * 1024 * 1024),
    ));
    $parts[] = array(
        'PartNumber' => $partNumber++,
        'ETag'       => $result['ETag'],
    );
}

// 4. Complete multipart upload.
$result = $s3->completeMultipartUpload(array(
    'Bucket'   => $bucket,
    'Key'      => $key,
    'UploadId' => $uploadId,
    'Parts'    => $parts,
));
$url = $result['Location'];

fclose($file);