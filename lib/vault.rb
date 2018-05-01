require "erb"
require "gibberish"
require "slop"
require "yaml"

##################################################################################################
# main class
##################################################################################################
class Vault
  @env = nil
  @dir = nil
  @password = nil
  @secret = nil

  ##################################################################################################
  # init class
  ##################################################################################################
  def initialize(command_line_options = ARGV)
    parser = Slop::Parser.new cli_flags
    arguments = parse_arguments(command_line_options, parser)

    # at least we need to know what we should do
    unless arguments[:seal] || arguments[:unseal]
      puts "ERROR please set seal or unseal as command"
      puts cli_flags
      exit(1)
    end

    # set global vars
    @env = arguments[:environment]
    @dir = arguments[:directory]
    @password = arguments[:password]
    @secret = arguments[:secret]

    # set vaults
    @vault_file = ["vault", @env, "yaml"].compact.join(".")
    @vault_file_enc = ["vault", @env, "enc", "yaml"].compact.join(".")

    secret_file = [@dir, @secret].join("/")
    # read password
    @vault_password = File.read(secret_file) if File.exist?(secret_file)
    @vault_password = @password unless @password.to_s.empty?

    # check if password is present
    if @vault_password.to_s.empty?
      puts "ERROR: no password (file) is set"
      exit(1)
    end

    # create cipher
    @cipher = Gibberish::AES.new(@vault_password)

    # some meta info
    puts "You are switching to stage #{@env}}" unless @env.nil?
    puts "Using vault: #{@vault_file_enc}"
    puts "Using plain vault: #{@vault_file}"
    puts "*" * 20

    seal if arguments[:seal]
    unseal if arguments[:unseal]
  end

  ##################################################################################################
  # encrypt the vault
  ##################################################################################################
  def seal
    unless File.exist?(@vault_file)
      puts "vault file does not exist: #{@vault_file}"
      exit(1)
    end

    # read plain config file
    vault = YAML.load_file(@vault_file)

    # walk trough all files and entries
    vault["files"].each do |file|
      puts "encrypting config for #{file["name"]}"

      file["env"].each do |env|
        env["value"] = @cipher.encrypt(env["value"].to_s) if env.has_key?("encrypt") && env["encrypt"] == true
      end
    end

    # write encrypted vault
    File.open(@vault_file_enc, "w") { |f| f.write vault.to_yaml }
  end

  ##################################################################################################
  # decrypt the vault
  ##################################################################################################
  def unseal
    unless File.exist?(@vault_file_enc)
      puts "encrypted vault file does not exist: #{@vault_file_enc}"
      exit(1)
    end

    # load vault
    vault = YAML.load_file(@vault_file_enc)

    # walk through files and entries
    vault["files"].each do |file|

      # collect all keys and values and uncrypt if needed
      data = {}
      file["env"].each do |env|
        value = env["value"]
        value = @cipher.decrypt(env["value"]).to_s if env.has_key?("encrypt") && env["encrypt"] == true
        env["value"] = value

        data[env["name"]] = value
      end
    end

    # write unencrypted config file
    puts "writing file #{@vault_file}"

    File.open(@vault_file, "w") { |f| f.write vault.to_yaml }

    generate_files
  end

  ##################################################################################################
  # generate config files from erb templates
  ##################################################################################################
  def generate_files
    unless File.exist?(@vault_file)
      puts "vault file does not exist: #{@vault_file}"
      exit(1)
    end

    vault = YAML.load_file(@vault_file)

    # walk through files and entries
    vault["files"].each do |file|

      # collect all keys and values and uncrypt if needed
      data = {}
      file["env"].each do |env|
        value = env["value"]
        data[env["name"]] = value
      end

      config_file = [@dir, file["name"]].join("/")

      if file.has_key?("template")
        # render template if present?
        template_file = [@dir, file["template"]].join("/")

        puts "writing file #{config_file} from template #{template_file}"

        unless File.exist?(template_file)
          puts "vault file does not exist: #{template_file}"
          exit(1)
        end

        File.open(config_file, "w") do |f|
          # the keys inside erb needs to be lower case
          f.write ERB.new(File.read(template_file)).result_with_hash(Hash[data.map { |k, v| [k.downcase, v] }])
        end
      else
        # write normal env file
        puts "writing file #{file["name"]}"
        File.open(config_file, "w") do |env_file|
          if file.has_key?("value_only")
            content = file["env"].first
            env_file.write(content["value"])
          else
            data.each do |key, value|
              env_file.write("#{key}=#{value}\n")
            end
          end
        end
      end
    end
  end

  ##################################################################################################
  # command line option helper
  ##################################################################################################
  def cli_flags
    options = Slop::Options.new
    options.banner = "usage: vault [command] [options] ..."
    options.separator ""
    options.separator "Command:"
    options.boolean "seal", "seal the vault"
    options.boolean "unseal", "unseal the vault"
    options.separator ""
    options.separator "Options:"

    options.string "-e", "--environment", "Set the environment you want to (un)seal", default: nil
    options.string "-d", "--directory", "Set the directory where to find the fault, default current directory", default: File.expand_path(File.dirname(__FILE__))

    options.string "-p", "--password", "Set the password of the vault", default: nil
    options.string "-f", "--secret", "Set the secret file name inside the directory", default: ".secret"

    options
  end

  ##################################################################################################
  # helper to work with the arguments
  ##################################################################################################
  def parse_arguments(command_line_options, parser)
    begin
      result = parser.parse command_line_options
      result.to_hash
    rescue Slop::UnknownOption
      puts cli_flags
      exit
    end
  end
end

##################################################################################################
# just ramp up the class
##################################################################################################
Vault.new
