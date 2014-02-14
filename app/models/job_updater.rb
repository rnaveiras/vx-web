class JobUpdater

  attr_reader :message, :build, :job

  def initialize(job_status_message)
    @message = job_status_message
  end

  def project
    @project ||= Project.lock(true).find_by(id: message.project_id)
  end

  def build
    @build ||= project && project.builds.find_by(id: message.build_id)
  end

  def job
    @job ||= build && build.jobs.find_by(number: message.job_id)
  end

  def perform
    guard do
      update_and_save_job_status
      truncate_job_logs
      start_build? and start_build
      all_jobs_finished? and finalize_build
      true
    end
  end

  private

    def guard
      Build.transaction do
        if project && build && job
          begin
            yield
          # TODO: save and compare messages
          rescue StateMachine::InvalidTransition => e
            Rails.logger.error "ERROR: #{e.inspect}"
            Airbrake.notify(e)
            :invalid_transition
          end
        end
      end
    end

    def truncate_job_logs
      if message.status == 2
        JobLog.where(job_id: job.id).delete_all

        message = {
          channel: "job_logs",
          event:   "truncate",
          payload: { event: "truncate", data: { job_id: job.id } }
        }
        ServerSideEventsConsumer.publish message
      end
    end

    def new_build_status
      if all_jobs_finished?
        build.jobs.maximum(:status)
      end
    end

    def all_jobs_finished?
      statuses = [3,4,5]
      build.jobs.where(status: statuses).count == build.jobs.count
    end

    def start_build?
      message.status == 2 && build.status_name == :initialized
    end

    def update_and_save_job_status
      case message.status
      when 0 # initialized
        nil
      when 2 # started
        job.started_at = tm
        job.start!
      when 3 # finished
        job.finished_at = tm
        job.pass!
      when 4 # failed
        job.finished_at = tm
        job.decline!
      when 5 # errored
        job.finished_at = tm
        job.error!
      end
    end

    def start_build
      build.started_at = tm
      build.start!
    end

    def finalize_build
      case new_build_status
      when 3
        build.finished_at = tm
        build.pass!
      when 4
        build.finished_at = tm
        build.decline!
      when 5
        build.finished_at = tm
        build.error!
      end
    end

    def create_deploy_if_need
      if build.passed?
        source = ::Vx::Builder::BuildConfiguration.new(build.source)
        if source.deploy?
          build.new_deploy_from_self
        end
      end
    end

    def tm
      @tm ||= Time.at(message.tm)
    end

end
