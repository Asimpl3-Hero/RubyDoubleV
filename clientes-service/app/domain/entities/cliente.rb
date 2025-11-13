# Domain Layer - Cliente Entity (Clean Architecture)
# This represents the core business entity with no external dependencies

module Domain
  module Entities
    class Cliente
      attr_reader :id, :nombre, :identificacion, :correo, :direccion, :created_at, :updated_at

      def initialize(id: nil, nombre:, identificacion:, correo:, direccion:, created_at: nil, updated_at: nil)
        @id = id
        @nombre = nombre
        @identificacion = identificacion
        @correo = correo
        @direccion = direccion
        @created_at = created_at
        @updated_at = updated_at

        validate!
      end

      def to_h
        {
          id: @id,
          nombre: @nombre,
          identificacion: @identificacion,
          correo: @correo,
          direccion: @direccion,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end

      private

      def validate!
        raise ArgumentError, 'Nombre es requerido' if @nombre.nil? || @nombre.strip.empty?
        raise ArgumentError, 'Identificación es requerida' if @identificacion.nil? || @identificacion.strip.empty?
        raise ArgumentError, 'Correo es requerido' if @correo.nil? || @correo.strip.empty?
        raise ArgumentError, 'Formato de correo inválido' unless valid_email?(@correo)
        raise ArgumentError, 'Dirección es requerida' if @direccion.nil? || @direccion.strip.empty?
      end

      def valid_email?(email)
        email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      end
    end
  end
end
