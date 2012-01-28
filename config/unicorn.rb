# ワーカーの数
worker_processes 2

# ソケット
listen File.dirname(__FILE__) + '/../tmp/sockets/unicorn-lokka.sock'

# pid
pid File.dirname(__FILE__) + '/../tmp/pids/unicorn-lokka.pid'

# ログ
stderr_path 'log/unicorn.log'
stdout_path 'log/unicorn.log'

# ダウンタイムなくす
preload_app true

before_fork do |server, worker|
  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      # SIGTTOU だと worker_processes が多いときおかしい気がする
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
