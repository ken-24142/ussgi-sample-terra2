import boto3
import os
import datetime

def lambda_handler(event, context):
  rds = boto3.client('rds')
  cluster_id = os.environ.get('DB_CLUSTER_IDENTIFIER', 'please_set_db_cluster_identifier_env')
  now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S')
  snapshot_id = f"{cluster_id}-snapshot-{now}"

  try:
    response = rds.create_db_cluster_snapshot(
      DBClusterSnapshotIdentifier=snapshot_id,
      DBClusterIdentifier=cluster_id
    )
    return {
      'statusCode': 200,
      'body': f"Snapshot {snapshot_id} created successfully.",
      'snapshot_arn': response['DBClusterSnapshot']['DBClusterSnapshotArn']
    }
  except Exception as e:
    import logging
    logger = logging.getLogger()
    logger.error(f"Failed to create snapshot: {str(e)}", exc_info=True)
    raise
