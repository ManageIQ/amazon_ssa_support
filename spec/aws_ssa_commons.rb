def config_aws_client_stub
  Aws.config[:sqs] = {
    :stub_responses => {
      :list_queues => { :queue_urls => ['https:://sqs.ap-northeast-1.awazonaws.com/123456789/test'] }
    }
  }
  Aws.config[:s3] = {
    :stub_responses => {
      :list_buckets => { :buckets => [{ :name => 's3_bucket' }] }
    }
  }
end

def mocked_log
  obj = double
  allow(obj).to receive(:info)
  allow(obj).to receive(:debug)
  allow(obj).to receive(:debug?).and_return(true)

  obj
end

def mocked_ebs_instance(id)
  mapping1 = double
  allow(mapping1).to receive_message_chain("ebs.volume_id") { 'vol_1' }

  mapping2 = double
  allow(mapping2).to receive_message_chain("ebs.volume_id") { 'vol_2' }

  obj = double
  allow(obj).to receive(:instance_id).and_return(id)
  allow(obj).to receive(:id).and_return(id)
  allow(obj).to receive(:block_device_mappings).and_return([mapping1, mapping2])
  allow(obj).to receive(:root_device_type).and_return('ebs')

  obj
end

def mocked_ebs_image(id)
  mapping1 = double
  allow(mapping1).to receive_message_chain("ebs.snapshot_id") { 'snap_1' }
  mapping2 = double
  allow(mapping2).to receive_message_chain("ebs.snapshot_id") { 'snap_2' }

  obj = double
  allow(obj).to receive(:image_id).and_return(id)
  allow(obj).to receive(:id).and_return(id)
  allow(obj).to receive(:block_device_mappings).and_return([mapping1, mapping2])
  allow(obj).to receive(:root_device_type).and_return('ebs')

  obj
end

def mocked_ec2
  obj = double
  allow(obj).to receive_message_chain("client.wait_until")
  allow(obj).to receive(:create_snapshot).and_return(mocked_snapshot("snap-mocked-1"))
  allow(obj).to receive(:snapshot).and_return(mocked_snapshot("snap-mocked-2"))
  allow(obj).to receive(:create_volume).and_return(mocked_volume("vol-mocked-1"))

  allow(obj).to receive(:image).and_return(mocked_ebs_image("ami-mocked-1"))
  allow(obj).to receive(:instance).and_return(mocked_ebs_instance("i-mocked-1"))
  obj
end

def mocked_snapshot(id)
  obj = double
  allow(obj).to receive(:id).and_return(id)
  allow(obj).to receive(:wait_until_completed)
  allow(obj).to receive(:create_tags)
  allow(obj).to receive(:delete)

  obj
end

def mocked_volume(id)
  obj = double
  attachment = double
  allow(attachment).to receive(:state).and_return('attached')

  allow(obj).to receive(:id).and_return(id)
  allow(obj).to receive(:attach_to_instance)
  allow(obj).to receive(:create_tags)
  allow(obj).to receive(:delete)
  allow(obj).to receive(:detach_from_instance).and_return(attachment)

  obj
end

def mocked_instances
  instances = []
  10.times.each do |i|
    instances << {
      :instance_id        => "instance_000000#{i}",
      :instance_type      => 'm3.medium',
      :image_id           => "image_id_#{i}",
      :private_ip_address => "11.#{(i / 255) == 0 ? 0 : i % (i / 255)}.#{i / 255}.#{i % 255}",
      :public_ip_address  => "41.#{(i / 255) == 0 ? 0 : i % (i / 255)}.#{i / 255}.#{i % 255}",
      :state              => {:name => 'running'},
      :architecture       => 'x86_64',
      :placement          => {:availability_zone => "us-east-1e"},
    }
  end
end
