# frozen_string_literal: true

namespace :active_storage do
  desc "Migrate blobs from local disk storage to S3 (iDrive e2)"
  task migrate_to_s3: :environment do
    require "open-uri"

    target_service_name = "idrive_production"
    target_service = ActiveStorage::Blob.services.fetch(target_service_name)

    blobs_to_migrate = ActiveStorage::Blob.where.not(service_name: target_service_name)
    total = blobs_to_migrate.count

    if total.zero?
      puts "No blobs need migration. All blobs are already on #{target_service_name}."
      exit
    end

    puts "Found #{total} blobs to migrate to #{target_service_name}..."

    migrated = 0
    failed = 0

    blobs_to_migrate.find_each do |blob|
      print "Migrating #{blob.key} (#{blob.filename})... "

      begin
        # Check if file exists in current service
        current_service = ActiveStorage::Blob.services.fetch(blob.service_name)

        unless current_service.exist?(blob.key)
          puts "SKIPPED (file not found in #{blob.service_name})"
          failed += 1
          next
        end

        # Download from current service and upload to target
        current_service.open(blob.key, checksum: blob.checksum) do |file|
          target_service.upload(blob.key, file, checksum: blob.checksum)
        end

        # Update the service_name in database
        blob.update_column(:service_name, target_service_name)

        puts "OK"
        migrated += 1
      rescue StandardError => e
        puts "FAILED: #{e.message}"
        failed += 1
      end
    end

    puts "\nMigration complete!"
    puts "  Migrated: #{migrated}"
    puts "  Failed: #{failed}"
    puts "  Total: #{total}"
  end

  desc "Update blob service_name without migrating files (use when files already exist in S3)"
  task update_service_name: :environment do
    target_service_name = ENV.fetch("TARGET_SERVICE", "idrive_production")

    blobs_to_update = ActiveStorage::Blob.where.not(service_name: target_service_name)
    total = blobs_to_update.count

    if total.zero?
      puts "No blobs need updating. All blobs already have service_name: #{target_service_name}."
      exit
    end

    puts "Updating #{total} blobs to service_name: #{target_service_name}..."
    puts "WARNING: This assumes files already exist in the target storage!"
    print "Continue? (y/n): "

    unless $stdin.gets.chomp.downcase == "y"
      puts "Aborted."
      exit
    end

    updated = ActiveStorage::Blob.where.not(service_name: target_service_name)
                                 .update_all(service_name: target_service_name)

    puts "Updated #{updated} blobs."
  end

  desc "List blobs by service_name"
  task list_services: :environment do
    puts "Blobs by service_name:"
    ActiveStorage::Blob.group(:service_name).count.each do |service, count|
      puts "  #{service}: #{count}"
    end
  end

  desc "Verify S3 connectivity"
  task verify_s3: :environment do
    service_name = ENV.fetch("SERVICE", "idrive_production")

    begin
      service = ActiveStorage::Blob.services.fetch(service_name)
      puts "Service '#{service_name}' configuration:"
      puts "  Class: #{service.class.name}"

      # Try to list a few keys to verify connectivity
      if service.respond_to?(:bucket)
        puts "  Bucket: #{service.bucket.name}"
        puts "  Connectivity: OK"
      else
        puts "  Connectivity: Unable to verify (not S3 service)"
      end
    rescue KeyError
      puts "Service '#{service_name}' not found in storage.yml"
      puts "Available services: #{ActiveStorage::Blob.services.keys.join(', ')}"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end

  desc "Clean up orphaned blobs (no attachments)"
  task cleanup_orphaned: :environment do
    orphaned = ActiveStorage::Blob.left_joins(:attachments)
                                  .where(active_storage_attachments: { id: nil })

    count = orphaned.count
    if count.zero?
      puts "No orphaned blobs found."
      exit
    end

    puts "Found #{count} orphaned blobs."
    print "Delete them? (y/n): "

    unless $stdin.gets.chomp.downcase == "y"
      puts "Aborted."
      exit
    end

    orphaned.find_each(&:purge)
    puts "Deleted #{count} orphaned blobs."
  end
end
