module RubyBuckets
  VERSION = "0.1.0"
end

require 'aws-sdk-s3'
require 'tk'
###############################################################################
###############################################################################
# Ruby_Bucket AWS Bucket management tool                                      #
# By Brian Rahming                                                            #
###############################################################################
###############################################################################

$region = 'us-west-2'
$title = 'Ruby Buckets'
PART_SIZE=1024 * 1024 * 100
class File
  def each_part(part_size=PART_SIZE)
    yield read(part_size) until eof?
  end
end

###############################################################################
###############################################################################
# Show Bucket Path Method --shows Bucket details                              #
###############################################################################
###############################################################################

def show_bucket_path
  unless $list.curselection.empty?
    begin
      idx = $list.curselection
      idx = idx[0]
      $bucket = $bucket_list[idx]
      $lb_bucket_name.text = "https://s3-#{$region}.amazonaws.com/#{$bucket}"
      $lb_bucket_region.text = $s3.client.get_bucket_location(bucket: $bucket).location_constraint
      $open_button.state = 'normal'
      $delete_button.state = 'normal'
      $bucket_public_read.state = 'normal'
      $bucket_public_write.state = 'normal'
      resp = $s3.client.get_bucket_acl(bucket: $bucket)
      $bucket_files = $s3.bucket($bucket).objects(prefix: '', delimiter: '').collect(&:key)
      $lb_bucket_items_qty.text = $bucket_files.count
      if resp.grants[1]
        get_permission = resp.grants[1].permission
        if get_permission == 'READ'
          $bucket_public_read.select()
        end
        get_permission2 = resp.grants[2].permission
        if get_permission2 == 'WRITE'
          $bucket_public_write.select()
        end
      end
    rescue
      Tk.messageBox('type' =>  'ok',
                    'icon' => 'error',
                    'title' => 'Object Select',
                    'message' => 'This Bucket is in a different Region')
      $open_button.state = 'disabled'
      $delete_button.state = 'disabled'
      $bucket_public_read.state = 'disabled'
      $bucket_public_write.state = 'disabled'
      $lb_bucket_name.text = ''
    end
  else
    Tk.messageBox('type' =>  'ok',
                  'icon' => 'error',
                  'title' => 'Object Select',
                  'message' => 'You need to select a Bucket')
  end
end

###############################################################################
###############################################################################
# Show Bucket Item Path Method --shows item details                           #
###############################################################################
###############################################################################

def show_item_path
  unless $list_Item.curselection.empty?
    idx =  $list_Item.curselection
    idx = idx[0]
    $bucket_item = $bucket_items[idx]
    $bucket_string = "https://s3-#{$region}.amazonaws.com/#{$bucket}/#{$bucket_item}"
    $save_file_button.state = 'normal'
    $delete_file_button.state = 'normal'
    $item_public_read.state = 'normal'
    $item_public_write.state = 'normal'
    $item_text.delete('1.0','end')
    $item_text.insert 'end',$bucket_string
    client = Aws::S3::Client.new(region: 'us-west-2')
    resp = client.get_object_acl(bucket: $bucket,key: $bucket_item)
    if resp.grants[1]
      get_permission = resp.grants[1].permission
      if get_permission == 'READ'
        $item_public_read.select()
      end
      # get_permission2 = resp.grants[2].permission
      # if get_permission2 == 'WRITE'
      #   $item_public_write.select()
      # end
    end
  else
    Tk.messageBox('type' =>  'ok',
                  'icon' => 'error',
                  'title' => 'Object Select',
                  'message' => 'You need to select a Object')
  end
end

###############################################################################
###############################################################################
# Bucket Public Read Access Method                                            #
###############################################################################
###############################################################################

def bucket_public_read
  if $bucket_public_read.variable() == 1
    $s3.client.put_bucket_acl(acl: 'public-read', bucket: $bucket)
  else
    $s3.client.put_bucket_acl(acl: 'private', bucket: $bucket)
  end
end

###############################################################################
###############################################################################
# Bucket Public Read Access Method                                            #
###############################################################################
###############################################################################

def bucket_public_write
  if $bucket_public_write.variable() == 1
    $s3.client.put_bucket_acl(acl: 'public-read-write',bucket: $bucket)
  else
    $s3.client.put_bucket_acl(acl: 'private',bucket: $bucket)
  end
end

###############################################################################
###############################################################################
# File Public Read Access Method                                              #
###############################################################################
###############################################################################

def file_public_read
  if $public_read.variable() == 1
    $s3.client.put_object_acl(acl: 'public-read',
                              bucket: $bucket,
                              key: $bucket_item)
  else
    $s3.client.put_object_acl(acl: 'private',
                              bucket: $bucket,
                              key: $bucket_item)
  end
end

###############################################################################
###############################################################################
# Save File Method --Saves file to computer                                   #
###############################################################################
###############################################################################

def save_file
  unless $list_Item.curselection.empty?
    idx =  $list_Item.curselection
    idx = idx[0]
    $bucket_item = $bucket_items[idx]
    obj = $s3.bucket($bucket).object($bucket_item)
    filename = Tk::getSaveFile(:initialfile => $bucket_item)
    begin
      if !filename.empty?
        obj.get(response_target: filename)
      end
    rescue
      Tk.messageBox('type' =>  'ok',
                    'icon' => 'error',
                    'title' => 'Cannot Save File',
                    'message' => 'Cannot Save File')
    end
  end
end

###############################################################################
###############################################################################
# Delete File Method --Deletes a file from Bucket                             #
###############################################################################
###############################################################################

def delete_file
  unless $list_Item.curselection.empty?
    idx =  $list_Item.curselection
    idx = idx[0]
    $bucket_item = $bucket_items[idx]
    ok_delete = Tk.messageBox('type' => 'okcancel',
                              'icon' => 'warning',
                              'title' =>  'Delete Bucket',
                              'message' => 'Delete item?')
    if ok_delete == 'ok'
      begin
        $s3.bucket($bucket).objects(prefix: $bucket_item).batch_delete!
      rescue => e
        Tk.messageBox('type' => 'ok',
                      'icon' =>  'error',
                      'title'   => 'Delete File',
                      'message' => "Cannot Delete File #{e}")
      end
    end
  end
end

###############################################################################
###############################################################################
# Upload File Method --Uploads a file to Bucket                               #
###############################################################################
###############################################################################

def upload_file
  filename = Tk::getOpenFile
  begin
    unless filename.empty?
      file = File.open(filename, 'rb')
      name = File.basename(filename)
      # test to see if the file is bigger than 100 MB for multipart upload
      if file.size > PART_SIZE
        input_opts = {
          bucket: $bucket,
          key: name,
        }
        mpu_create_response = $s3.client.create_multipart_upload(input_opts)
        total_parts = file.size.to_f / PART_SIZE
        current_part = 1
        file.each_part do |part|
          $s3.client.upload_part(body: part,
                                 bucket: $bucket,
                                 key: name,
                                 part_number: current_part,
                                 upload_id:   mpu_create_response.upload_id)
          percent_complete = (current_part.to_f / total_parts.to_f) * 100
          percent_complete = 100 if percent_complete > 100
          percent_complete = sprintf('%.2f', percent_complete.to_f)
          puts "percent complete: #{percent_complete}"
          current_part += 1
        end
        input_opts = input_opts.merge(upload_id: mpu_create_response.upload_id)
        parts_resp = $s3.client.list_parts(input_opts)
        input_opts = input_opts.merge(multipart_upload: {parts: parts_resp.parts.map do |part|
                                                                { part_number: part.part_number,
                                                                  etag: part.etag }
                                                                end })
        $s3.client.complete_multipart_upload(input_opts)
      else
        obj = $s3.bucket($bucket).object(name)
        obj.upload_file(filename)
        file.close
      end
      $bucket_item_window.destroy
      open_bucket
    end
  rescue => e
    Tk.messageBox('type' => 'ok',
                  'icon' => 'error',
                  'title' => 'Cannot Open File',
                  'message' => "Cannot Open File #{e}")
  end
  
end

###############################################################################
###############################################################################
# Reset Region Method                                                         #
###############################################################################
###############################################################################

def reset_region(region)
  $region = region
  $region_title.text = "Region: #{region}"
end

###############################################################################
###############################################################################
# Create Bucket Window Method --This opens a new window to create a bucket    #
###############################################################################
###############################################################################

def create_bucket_window
  $add_bucket_window = TkToplevel.new() { title 'Create Bucket' }
  $txt_input_bucket_name  = TkEntry.new($add_bucket_window)
  $txt_input_bucket_name.pack('side' => 'top', 'padx' => '10', 'pady' => '10')
  TkButton.new($add_bucket_window) {
    text 'Create Bucket'
    command(proc { create_bucket() })
    pack('side' => 'bottom', 'padx' => '5', 'pady' => '5')
  }
end

###############################################################################
###############################################################################
# Create Bucket Method                                                      #
###############################################################################
###############################################################################

def create_bucket
  new_bucket =  $txt_input_bucket_name.value
  bucket_exists = $s3.bucket(new_bucket).exists?
  if !bucket_exists
    begin
      $s3.create_bucket(bucket: new_bucket)
      $add_bucket_window.destroy
      connect_aws()
    rescue
      Tk.messageBox('type' => 'ok',
                    'icon' => 'error',
                    'title' =>  'Cannot Create Bucket',
                    'message' => 'Cannot Create Bucket')
    end
  else
    Tk.messageBox('type' => 'ok',
                  'icon' => 'error',
                  'title' =>  'Cannot create Bucket',
                  'message' => 'Cannot create Bucket because Bucket exists!')
  end
end

###############################################################################
###############################################################################
# Delete Bucket Method                                                      #
###############################################################################
###############################################################################

def delete_bucket
  ok_delete = Tk.messageBox('type' => 'okcancel',
                            'icon' => 'warning',
                            'title' =>  'Delete Bucket',
                            'message' => 'Delete Bucket?')
  if ok_delete == 'ok'
    if $bucket_files.count == 0
      begin
        $s3.client.delete_bucket(bucket: $bucket)
        connect_aws()
      rescue e
        Tk.messageBox('type' => 'ok',
                      'icon' => 'error',
                      'title' =>  'Cannot delete Bucket',
                      'message' => "Cannot delete Bucket! #{e}")
      end
    else
      Tk.messageBox('type' => 'ok',
                    'icon' => 'error',
                    'title' =>  'Cannot delete Bucket',
                    'message' => 'Cannot delete Bucket because Bucket is not empty!')
    end
  end
end

###############################################################################
###############################################################################
# Bucket Public Read Access Method                                          #
###############################################################################
###############################################################################

def open_bucket
  if !$list.curselection.empty? || !$bucket.empty?
    idx = $list.curselection
    idx = idx[0]
    $bucket = $bucket_list[idx]
    $bucket_item_window = TkToplevel.new() { title $bucket }
    $bucket_item_window.minsize(800,350)
    #$bucket_item_window.resizable(false,false)
    begin
      $bucket_items = $s3.bucket($bucket).objects(prefix:'', delimiter: '').collect(&:key)
    rescue
      Tk.messageBox('type' => 'ok',
                    'icon' => 'error',
                    'title' => 'Cannot Connect',
                    'message' => 'Cannot Connect to AWS')
    end
    items = TkVariable.new($bucket_items)
    item_list_frame = TkFrame.new($bucket_item_window) {
      relief 'groove'
      borderwidth 1
      padx 5
      pady 5
      place('relx' => 0.01, 'rely' => 0.02)
    }
    $list_Item = TkListbox.new(item_list_frame) do
      listvariable items
      pack('padx' => 5, 'pady' => 10, 'fill' => 'y','side' => 'left')
    end
    scroll = TkScrollbar.new(item_list_frame) do
      orient 'vertical'
      pack('pady' => 10,'fill' => 'y', 'side' => 'left')
    end
    $list_Item.yscrollcommand(proc { |*args|
      scroll.set(*args)
    })
    scroll.command(proc { |*args|
      $list_Item.yview(*args)
    })
    item_info = TkFrame.new($bucket_item_window) {
      relief 'groove'
      borderwidth 1
      padx 1
      pady 1
      place('relx' => 0.32, 'rely' => 0.02)
    }
    $item_text = TkText.new(item_info) do
      height 3
      width 60
      font TkFont.new('times 15 bold')
      pack('side' => 'top',  'padx' => '5', 'pady' => '5', 'fill' => 'x')
    end
    TkButton.new(item_info) {
      text 'Select file'
      command(proc { show_item_path() })
      pack('side' => 'bottom', 'padx' => '5', 'pady' => '5')
    }
    item_actions = TkFrame.new($bucket_item_window) {
      relief 'groove'
      borderwidth 1
      padx 10
      pady 1
      place('relx' => 0.32, 'rely' => 0.40)
    }
    $save_file_button = TkButton.new(item_actions) {
      text 'Save File'
      command(proc { save_file() })
      pack('side' => 'top', 'padx' => '5', 'pady' => '5')
      state 'disabled'
    }
    $delete_file_button = TkButton.new(item_actions) {
      text 'Delete File'
      command (proc { delete_file()  })
      pack('side' => 'top', 'padx' => '5', 'pady' => '5')
      state 'disabled'
    }
    TkButton.new(item_actions) {
      text 'Upload File'
      command(proc { upload_file() })
      pack('side' => 'top', 'padx' => '5', 'pady' => '5')
    }
    item_permission = TkFrame.new($bucket_item_window) {
      relief 'groove'
      borderwidth 1
      padx 10
      pady 1
      place('relx' => 0.50, 'rely' => 0.40)
    }
    $lbl_bucket_item_everyone = TkLabel.new(item_permission) {
      text 'Public Access:'
      foreground 'black'
      pack('side' => 'left')
    }
    $item_public_read = TkCheckButton.new(item_permission) do
      text 'Read:'
      relief 'groove'
      height 5
      pack('side' => 'left')
      command(proc {  file_public_read() })
      state 'disabled'
    end
    $item_public_write = TkCheckButton.new(item_permission) do
      text 'Write:'
      relief 'groove'
      height 5
      pack('side' => 'left')
      command(proc { file_public_read() })
      state 'disabled'
    end
    quit_frame = TkFrame.new($bucket_item_window) {
      relief 'groove'
      borderwidth 1
      padx 5
      pady 5
      place('relx' => 0.35,'rely' => 0.80)
    }
    TkButton.new(quit_frame) {
      text 'Close Window'
      command "$bucket_item_window.destroy"
      pack('padx' => '50', 'pady' => '10', 'side' => 'right')
    }
  else
    Tk.messageBox('type' => 'ok',
                  'icon' => 'error',
                  'title' => 'Select Bucket',
                  'message' => 'Please Select a Bucket')
  end
end

###############################################################################
###############################################################################
# Create Bucket Method                                                      #
###############################################################################
###############################################################################

def connect_aws
  begin
    $s3 = Aws::S3::Resource.new(region: $region)
    $bucket_list = Array.new($s3.buckets.count)
    ct = 0
    $s3.buckets.each do |bucket|
      $bucket_list.insert(ct, bucket.name)
      ct += 1
    end
    items = TkVariable.new($bucket_list)
    bucket_list_frame = TkFrame.new($main_window) {
      relief 'groove'
      borderwidth 1
      padx 5
      pady 5
      place('relx' => 0.1,'rely' => 0.20)
    }
    $list = TkListbox.new(bucket_list_frame) do
      listvariable items
      pack('padx' => 5, 'pady' => 10,'fill' => 'y','side' => 'left')
    end
    scroll = TkScrollbar.new(bucket_list_frame) do
      orient 'vertical'
      pack('pady' => 10, 'fill' => 'y', 'side' => 'left')
    end
    $list.yscrollcommand(proc { |*args|
      scroll.set(*args)
    })
    scroll.command(proc { |*args|
      $list.yview(*args)
    })
    $select_button.state = 'normal'
    $create_bucket.state = 'normal'
  rescue
    Tk.messageBox('type' => 'ok',
                  'icon' => 'error',
                  'title' => 'Cannot Connect',
                  'message' => 'Cannot Connect to AWS')
  end
end

###############################################################################
###############################################################################
# Main Window                                                                 #
###############################################################################
###############################################################################
$main_window = TkRoot.new {
  width 800
  height 400
}
$main_window.title = $title
file_menu = TkMenu.new($main_window)
options_menu = TkMenu.new($main_window)
options_menu.add('command',
  'label' => 'us-east-1, US East(N. Virginia)',
  'command' => (proc { reset_region('us-east-1') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'us-east-2, US East(Ohio)',
  'command'   => (proc { reset_region('us-east-2') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'us-west-1, US West(N. California)',
  'command'   => (proc { reset_region('us-west-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'us-west-2, US West(Oregon)',
  'command'   => (proc { reset_region('us-west-2') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'ca-central-1, Canada(Central)',
  'command'  => (proc { reset_region('ca-central-1') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'eu-central-1, EU(Frankfurt)',
  'command' => (proc { reset_region('eu-central-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'eu-west-1, EU(Ireland)',
  'command' => (proc { reset_region('eu-west-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'eu-west-2, EU(London)',
  'command' => (proc { reset_region('eu-west-2') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'eu-west-3, EU(Paris)',
  'command' => (proc { reset_region('eu-west-3') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'ap-northeast-1, Asia Pacific(Tokyo)',
  'command' => (proc { reset_region('ap-northeast-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'ap-northeast-2, Asia Pacific(Seoul)',
  'command' => (proc { reset_region('ap-northeast-2') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'ap-northeast-3, Asia Pacific(Osaka-Local)',
  'command' => (proc { reset_region('ap-northeast-3') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'ap-southeast-1, Asia Pacific(Singapore)',
  'command' => (proc { reset_region('ap-southeast-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'ap-southeast-2, Asia Pacific(Sydney)',
  'command'   => (proc { reset_region('ap-southeast-2') }),
  'underline' => 3)
options_menu.add('command',
  'label'  => 'ap-south-1, Asia Pacific(Mumbai)',
  'command' => (proc { reset_region('ap-south-1') }),
  'underline' => 3)
options_menu.add('command',
  'label' => 'sa-east-1, South America(São Paulo)',
  'command'   => (proc { reset_region('sa-east-1') }),
  'underline' => 3)
file_menu.add('separator')
file_menu.add('command',
              'label' => 'Connect to AWS',
              'command' => (proc { connect_aws() }),
              'underline' => 3)
menu_bar = TkMenu.new
menu_bar.add('cascade',
             'menu'  => file_menu,
             'label' => 'Go')
menu_bar.add('cascade',
              'menu'  => options_menu,
              'label' => 'Options')
$main_window.menu(menu_bar)
title_frame = TkFrame.new($main_window) {
  relief 'groove'
  borderwidth 1
  padx 5
  pady 5
  place('relx' => 0.1,'rely' => 0.03)
}
TkLabel.new(title_frame) {
  text $title
  foreground 'black'
  pack('padx' => 200, 'pady' => 2, 'side' => 'top', 'fill' => 'x')
}
$region_title = TkLabel.new(title_frame) {
  text "Region: #{$region}"
  foreground 'black'
  pack('padx' => 200, 'pady' => 1, 'side' => 'bottom')
}
bucket_action = TkFrame.new($main_window) {
  relief 'groove'
  borderwidth 1
  padx 1
  pady 1
  place('relx'=> 0.43,'rely'=>0.60)
}
$select_button = TkButton.new(bucket_action) {
  text 'Select Bucket'
  command(proc { show_bucket_path() })
  pack('padx' => '5', 'pady' => '5')
  state 'disabled'
}
$open_button = TkButton.new(bucket_action) {
  text 'Open Bucket'
  command(proc { open_bucket() }) 
  pack('padx' => '5', 'pady' => '5')
  state 'disabled'
}
$delete_button = TkButton.new(bucket_action) {
  text 'Delete Bucket'
  command(proc { delete_bucket() })
  pack('padx' => '5', 'pady' => '5')
  state 'disabled'
}
$create_bucket = TkButton.new(bucket_action) {
  text 'Create Bucket'
  command(proc {  create_bucket_window() }) 
  pack('side' => 'left', 'padx' => '5', 'pady' => '5')
  state 'disabled'
}
bucket_info_frame = TkFrame.new($main_window) {
  relief 'groove'
  borderwidth 1
  padx 1
  pady 1
  place('relx' => 0.43,'rely' => 0.20)
}
$lb_bucket_name = TkLabel.new(bucket_info_frame) {
  text 'Bucket Name:'
  foreground 'black'
  pack('padx' => 5, 'pady' => 5, 'side' => 'top', 'fill' => 'x')
}
$lb_bucket_region = TkLabel.new(bucket_info_frame) {
  text 'Bucket region:'
  foreground 'black'
  pack('padx' => 5, 'pady' => 5, 'side' => 'top')
}
bucket_items_frame = TkFrame.new(bucket_info_frame) {
  relief 'groove'
  borderwidth 1
  padx 1
  pady 1
  pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
}
lb_bucket_items_name = TkLabel.new(bucket_items_frame) {
  text 'Bucket items:'
  foreground 'black'
  pack('padx' => 5, 'pady' => 5, 'side' => 'left')
}
$lb_bucket_items_qty = TkLabel.new(bucket_items_frame) {
  text '0'
  foreground 'black'
  pack('padx' => 5, 'pady' => 5, 'side' => 'right')
}
bucket_permissions_frame = TkFrame.new($main_window) {
  relief 'groove'
  borderwidth 1
  padx 5
  pady 5
  place('relx'=>0.43,'rely'=>0.48)
}
TkLabel.new(bucket_permissions_frame) {
  text 'Public Access:'
  foreground 'black'
  pack('padx' => 0, 'pady' => 5, 'side' => 'left')
}
$bucket_public_read = TkCheckButton.new(bucket_permissions_frame) do
  text 'Read'
  relief 'groove'
  pack('side' => 'left')
  command(proc {  bucket_public_read() })
  state 'disabled'
end
$bucket_public_write = TkCheckButton.new(bucket_permissions_frame) do
  text 'Write'
  relief 'groove'
  pack('side' => 'left')
  command(proc {  bucket_public_write() })
  state 'disabled'
end
Tk.mainloop